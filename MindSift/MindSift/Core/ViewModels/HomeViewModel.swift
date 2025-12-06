//
//  HomeViewModel.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Managers
    let audioManager = AudioManager()
    let speechManager = SpeechManager()
    let calendarManager = CalendarManager()
    let networkManager = NetworkManager()
    let searchManager = SearchManager()
    
    private let geminiService = GeminiService()
    
    // MARK: - UI States
    @Published var isAnalyzing: Bool = false
    @Published var showSettings: Bool = false
    @Published var showMindMap: Bool = false
    @Published var showNetworkAlert: Bool = false
    @Published var networkErrorMessage: String = ""
    
    // Arama ve Filtreleme
    @Published var searchText: String = ""
    @Published var selectedType: NoteType? = nil
    
    // 👇 YENİ: Sonuçlar artık burada tutuluyor
    @Published var filteredNotes: [VoiceNote] = []
    
    init() {
        audioManager.checkPermissions()
        speechManager.checkPermissions()
    }
    
    // MARK: - Search Logic (Arama Tetikleyici)
    
    // View'dan çağrılacak ana fonksiyon
    func triggerSearch(with allNotes: [VoiceNote]) {
        Task {
            // Arama yöneticisini asenkron olarak çağır
            let results = await searchManager.search(
                query: searchText,
                notes: allNotes,
                selectedType: selectedType
            )
            
            // Sonuçları güncelle (MainActor sayesinde UI thread'de çalışır)
            self.filteredNotes = results
        }
    }
    
    // MARK: - Business Logic
    
    func handleDeepLink(url: URL) {
        if url.scheme == "mindsift" && url.host == "record" {
            print("🚀 Kestirme algılandı: Kayıt Başlatılıyor...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.audioManager.isRecording {
                    self.audioManager.startRecording()
                }
            }
        }
    }
    
    func processAudio(url: URL, context: ModelContext) {
        guard networkManager.isConnected else {
            showNetworkAlert = true
            networkErrorMessage = AppConstants.Texts.Errors.noInternet
            
            let newNote = VoiceNote(
                audioFileName: url.lastPathComponent,
                transcription: nil,
                title: "Beklemede (İnternet Yok)",
                summary: "Analiz için internet bağlantısı bekleniyor...",
                type: .unclassified,
                isProcessed: false
            )
            context.insert(newNote)
            return
        }
        
        isAnalyzing = true
        
        speechManager.transcribeAudio(url: url) { [weak self] text in
            guard let self = self else { return }
            
            guard let text = text, !text.isEmpty else {
                self.isAnalyzing = false
                return
            }
            
            self.geminiService.analyzeText(text: text) { result in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    
                    switch result {
                    case .success(let analysis):
                        self.saveAnalyzedNote(
                            text: text,
                            analysis: analysis,
                            audioURL: url,
                            context: context
                        )
                        
                    case .failure(let error):
                        print("AI Hatası: \(error.localizedDescription)")
                        let newNote = VoiceNote(
                            audioFileName: url.lastPathComponent,
                            transcription: text,
                            title: AppConstants.Texts.Errors.analysisFailed,
                            summary: error.localizedDescription,
                            type: .unclassified
                        )
                        context.insert(newNote)
                    }
                }
            }
        }
    }
    
    func processPendingNotes(allNotes: [VoiceNote]) {
        guard networkManager.isConnected else { return }
        
        let pendingNotes = allNotes.filter { !$0.isProcessed }
        
        for note in pendingNotes {
            let appGroupIdentifier = "group.com.devmustafatavasli.MindSift"
            
            guard let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
                return
            }
            let fileUrl = containerUrl.appendingPathComponent(
                note.audioFileName
            )
            
            speechManager.transcribeAudio(url: fileUrl) { [weak self] text in
                guard let self = self, let text = text, !text.isEmpty else {
                    return
                }
                
                self.geminiService.analyzeText(text: text) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let analysis):
                            self.updateNoteWithAnalysis(
                                note: note,
                                text: text,
                                analysis: analysis
                            )
                        case .failure(let error):
                            print("Pending Process Hatası: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func deleteNote(_ note: VoiceNote, context: ModelContext) {
        context.delete(note)
    }
    
    // MARK: - Private Helpers
    
    private func saveAnalyzedNote(
        text: String,
        analysis: AIAnalysisResult,
        audioURL: URL,
        context: ModelContext
    ) {
        // Asenkron işlem (Embedding)
        Task {
            // 1. Vektör Oluştur
            let vector = await EmbeddingManager.shared.generateEmbedding(
                from: text
            )
            
            // 2. Kaydet (Main Thread)
            await MainActor.run {
                let type = NoteType(rawValue: analysis.type) ?? .unclassified
                let eventDate = parseDate(from: analysis.event_date)
                
                if let date = eventDate, (type == .meeting || type == .task) {
                    calendarManager
                        .addEvent(
                            title: analysis.title,
                            date: date,
                            notes: analysis.summary
                        )
                }
                
                let newNote = VoiceNote(
                    audioFileName: audioURL.lastPathComponent,
                    transcription: text,
                    title: analysis.title,
                    summary: analysis.summary,
                    priority: analysis.priority,
                    eventDate: eventDate,
                    emailSubject: analysis.email_subject,
                    emailBody: analysis.email_body,
                    smartIcon: analysis.suggested_icon,
                    smartColor: analysis.suggested_color,
                    embedding: vector, // ✨ Vektör Kaydı
                    type: type,
                    isProcessed: true
                )
                context.insert(newNote)
                print(
                    "💾 VERİTABANI ONAYI: Not kaydedildi. Vektör Boyutu: \(vector?.count ?? 0)"
                )
            }
        }
    }
    
    private func updateNoteWithAnalysis(
        note: VoiceNote,
        text: String,
        analysis: AIAnalysisResult
    ) {
        // Güncelleme sırasında da vektör oluşturulmalı
        Task {
            let vector = await EmbeddingManager.shared.generateEmbedding(
                from: text
            )
            
            await MainActor.run {
                note.transcription = text
                note.title = analysis.title
                note.summary = analysis.summary
                note.type = NoteType(rawValue: analysis.type) ?? .unclassified
                note.priority = analysis.priority
                note.emailSubject = analysis.email_subject
                note.emailBody = analysis.email_body
                note.smartIcon = analysis.suggested_icon
                note.smartColor = analysis.suggested_color
                note.eventDate = parseDate(from: analysis.event_date)
                note.embedding = vector // ✨
                note.isProcessed = true
            }
        }
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        if let date = isoFormatter.date(from: dateString) { return date }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm"
        ]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) { return date }
        }
        return nil
    }
    
    // MARK: - 🧪 DEBUG / TEST (Simülatör İçin)
        
    /// Simülatörde mikrofon çalışmadığı için sistemi manuel test etmemizi sağlar.
    func debugSimulateRecording(context: ModelContext) {
        let testText = "Yarın sabah 9'da proje sunumu için ekiple toplantı yapmam lazım."
        print("🧪 Test Başlatıldı: Metin sisteme enjekte ediliyor...")
            
        // Sanki kayıt bitmiş ve metne çevrilmiş gibi davran
        self.isAnalyzing = true
            
        // Doğrudan Gemini analizine gönder
        self.geminiService.analyzeText(text: testText) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                    
                switch result {
                case .success(let analysis):
                    print("✅ Gemini Analizi Başarılı. Kaydediliyor...")
                    // Rastgele bir dosya ismi uydur
                    let fakeURL = URL(fileURLWithPath: "debug_audio.m4a")
                    self.saveAnalyzedNote(
                        text: testText,
                        analysis: analysis,
                        audioURL: fakeURL,
                        context: context
                    )
                        
                case .failure(let error):
                    print("❌ Gemini Test Hatası: \(error.localizedDescription)")
                }
            }
        }
    }
}
