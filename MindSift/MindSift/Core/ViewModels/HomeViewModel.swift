//
//  HomeViewModel.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import Foundation
import SwiftData
import SwiftUI
import Observation

@MainActor
@Observable
class HomeViewModel {
    
    // MARK: - Managers
    var audioManager = AudioManager()
    var speechManager = SpeechManager()
    var searchManager = SearchManager()
    
    let calendarManager = CalendarManager()
    let networkManager = NetworkManager()
    private let geminiService = GeminiService()
    
    // MARK: - UI States
    var isAnalyzing: Bool = false
    var showSettings: Bool = false
    var showMindMap: Bool = false
    var showNetworkAlert: Bool = false
    var networkErrorMessage: String = ""
    
    // Arama ve Filtreleme
    var searchText: String = ""
    var selectedType: NoteType? = nil
    var filteredNotes: [VoiceNote] = []
    
    init() {
        audioManager.checkPermissions()
        speechManager.checkPermissions()
        
        // 👇 YENİ: İnternet gelince otomatik tetiklenme
        networkManager.onStatusChange = { [weak self] isConnected in
            if isConnected {
                print(
                    "🌐 İnternet bağlantısı algılandı. Bekleyen notlar işleniyor..."
                )
                self?.processPendingNotes()
            }
        }
    }
    
    // MARK: - Search Logic
    
    func triggerSearch(with allNotes: [VoiceNote]) {
        guard !searchText.isEmpty || selectedType != nil else {
            self.filteredNotes = allNotes
            return
        }
        
        Task {
            let results = await searchManager.search(
                query: searchText,
                notes: allNotes,
                selectedType: selectedType
            )
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
        // 1. İnternet Kontrolü
        guard networkManager.isConnected else {
            showNetworkAlert = true
            networkErrorMessage = AppConstants.Texts.Errors.noInternet
            saveFallbackNote(
                url: url,
                context: context,
                title: "Beklemede (İnternet Yok)",
                summary: "Analiz için internet bekleniyor."
            )
            return
        }
        
        isAnalyzing = true
        
        // 2. Ses -> Metin
        speechManager.transcribeAudio(url: url) { [weak self] text in
            guard let self = self else { return }
            
            guard let transcription = text, !transcription.isEmpty else {
                print(
                    "⚠️ Transkripsiyon boş döndü, ham ses kaydı oluşturuluyor."
                )
                self.isAnalyzing = false
                self.saveFallbackNote(
                    url: url,
                    context: context,
                    title: "Ses Kaydı",
                    summary: "Metne çevrilemedi veya konuşma algılanamadı."
                )
                return
            }
            
            // 3. Metin -> AI Analiz
            self.geminiService.analyzeText(text: transcription) { result in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    
                    switch result {
                    case .success(let analysis):
                        self.saveAnalyzedNote(
                            text: transcription,
                            analysis: analysis,
                            audioURL: url,
                            context: context
                        )
                        
                    case .failure(let error):
                        print("❌ AI Hatası: \(error.localizedDescription)")
                        self.saveFallbackNote(
                            url: url,
                            context: context,
                            title: AppConstants.Texts.Errors.analysisFailed,
                            summary: error.localizedDescription,
                            transcription: transcription
                        )
                    }
                }
            }
        }
    }
    
    // 👇 GÜNCEL: Parametresiz, kendi verisini çeken fonksiyon
    func processPendingNotes() {
        guard networkManager.isConnected else { return }
        
        // Veritabanına doğrudan erişim (View'dan bağımsız)
        let context = DataController.shared.container.mainContext
        
        do {
            // İşlenmemiş notları bul (Fetch)
            // Not: FetchDescriptor predicate içinde bool kontrolü SwiftData'da bazen hassastır,
            // bu yüzden en temiz haliyle 'isProcessed == false' arıyoruz.
            let descriptor = FetchDescriptor<VoiceNote>(
                predicate: #Predicate { $0.isProcessed == false }
            )
            let pendingNotes = try context.fetch(descriptor)
            
            if pendingNotes.isEmpty { return }
            print("🔄 Bekleyen \(pendingNotes.count) not bulundu, işleniyor...")
            
            for note in pendingNotes {
                let fileUrl = StorageManager.shared.getFileURL(
                    fileName: note.audioFileName
                )
                
                speechManager
                    .transcribeAudio(url: fileUrl) { [weak self] text in
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
        } catch {
            print("❌ Bekleyen notlar getirilemedi: \(error)")
        }
    }
    
    func deleteNote(_ note: VoiceNote, context: ModelContext) {
        StorageManager.shared.deleteFile(fileName: note.audioFileName)
        context.delete(note)
        
        if let index = filteredNotes.firstIndex(where: { $0.id == note.id }) {
            filteredNotes.remove(at: index)
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveAnalyzedNote(
        text: String,
        analysis: AIAnalysisResult,
        audioURL: URL,
        context: ModelContext
    ) {
        Task {
            let vector = await EmbeddingManager.shared.generateEmbedding(
                from: text
            )
            
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
                    embedding: vector,
                    type: type,
                    isProcessed: true
                )
                
                context.insert(newNote)
                try? context.save()
                self.filteredNotes.insert(newNote, at: 0)
                print("💾 BAŞARILI: Not kaydedildi: \(analysis.title)")
            }
        }
    }
    
    private func saveFallbackNote(
        url: URL,
        context: ModelContext,
        title: String,
        summary: String,
        transcription: String? = nil
    ) {
        let newNote = VoiceNote(
            audioFileName: url.lastPathComponent,
            transcription: transcription,
            title: title,
            summary: summary,
            type: .unclassified,
            isProcessed: false
        )
        context.insert(newNote)
        try? context.save()
        self.filteredNotes.insert(newNote, at: 0)
        print("💾 FALLBACK: Yedek not kaydedildi.")
    }
    
    private func updateNoteWithAnalysis(
        note: VoiceNote,
        text: String,
        analysis: AIAnalysisResult
    ) {
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
                note.embedding = vector
                note.isProcessed = true
                try? note.modelContext?.save()
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
    
    func debugSimulateRecording(context: ModelContext) {
        let testText = "Yarın sabah 9'da proje sunumu için ekiple toplantı yapmam lazım."
        print("🧪 Test Başlatıldı...")
        self.isAnalyzing = true
            
        self.geminiService.analyzeText(text: testText) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                switch result {
                case .success(let analysis):
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
