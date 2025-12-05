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
// Ana ekranın tüm iş mantığını, durumunu (State) ve servis iletişimini yönetir.

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Managers
    // View yerine artık ViewModel bu yöneticilere sahip
    let audioManager = AudioManager()
    let speechManager = SpeechManager()
    let calendarManager = CalendarManager()
    let networkManager = NetworkManager()
    let searchManager = SearchManager() // ✨ YENİ EKLENDİ
    
    private let geminiService = GeminiService()
    
    // MARK: - UI States (Yayıncılar)
    @Published var isAnalyzing: Bool = false
    @Published var showSettings: Bool = false
    @Published var showMindMap: Bool = false
    @Published var showNetworkAlert: Bool = false
    @Published var networkErrorMessage: String = ""
    
    // Arama ve Filtreleme Durumları
    @Published var searchText: String = ""
    @Published var selectedType: NoteType? = nil
    
    // MARK: - Init
    init() {
        // İzinleri ViewModel başlatılırken kontrol et
        audioManager.checkPermissions()
        speechManager.checkPermissions()
    }
    
    // MARK: - Business Logic (İş Mantığı)
    
    /// Dışarıdan gelen linkleri (URL Scheme) işler
    func handleDeepLink(url: URL) {
        if url.scheme == "mindsift" && url.host == "record" {
            print("🚀 Kestirme algılandı: Kayıt Başlatılıyor...")
            // UI'ın tamamen yüklenmesi için minik bir gecikme
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.audioManager.isRecording {
                    self.audioManager.startRecording()
                }
            }
        }
    }
    
    /// Ses kaydı bittiğinde tetiklenen ana süreç
    func processAudio(url: URL, context: ModelContext) {
        // 1. İnternet Kontrolü
        guard networkManager.isConnected else {
            showNetworkAlert = true
            networkErrorMessage = AppConstants.Texts.Errors.noInternet
            
            // İnternet yoksa notu "Beklemede" olarak kaydet
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
        
        // 2. İşlem Başlıyor
        isAnalyzing = true
        
        // 3. Sesi Yazıya Dök
        speechManager.transcribeAudio(url: url) { [weak self] text in
            guard let self = self else { return }
            
            guard let text = text, !text.isEmpty else {
                self.isAnalyzing = false
                return
            }
            
            // 4. AI Analizi (Gemini)
            self.geminiService.analyzeText(text: text) { result in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    
                    switch result {
                    case .success(let analysis):
                        // 5. Başarılı Sonucu Kaydet
                        self.saveAnalyzedNote(
                            text: text,
                            analysis: analysis,
                            audioURL: url,
                            context: context
                        )
                        
                    case .failure(let error):
                        print("AI Hatası: \(error.localizedDescription)")
                        // Hata olsa bile ham veriyi kaydet
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
    
    /// Share Extension'dan gelen ve henüz işlenmemiş notları bulup işler
    func processPendingNotes(allNotes: [VoiceNote]) {
        // İnternet yoksa işlem yapma
        guard networkManager.isConnected else { return }
        
        let pendingNotes = allNotes.filter { !$0.isProcessed }
        
        for note in pendingNotes {
            print("🔄 İşlenmemiş not bulundu: \(note.title ?? "")")
            
            // Dosyayı App Group içinden bul
            // (İleride bu ID'yi de Constant'a taşıyacağız)
            let appGroupIdentifier = "group.com.devmustafatavasli.MindSift" // Güncellendi
            
            guard let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
                return
            }
            let fileUrl = containerUrl.appendingPathComponent(
                note.audioFileName
            )
            
            // Analiz Akışı (Mevcut notu güncelleyerek)
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
    
    /// Notu siler
    func deleteNote(_ note: VoiceNote, context: ModelContext) {
        context.delete(note)
    }
    
    // MARK: - Private Helpers (Veritabanı İşlemleri)
    
    private func saveAnalyzedNote(
        text: String,
        analysis: AIAnalysisResult,
        audioURL: URL,
        context: ModelContext
    ) {
        let type = NoteType(rawValue: analysis.type) ?? .unclassified
        let eventDate = parseDate(from: analysis.event_date)
        
        // Takvime Ekleme
        if let date = eventDate, (type == .meeting || type == .task) {
            calendarManager
                .addEvent(
                    title: analysis.title,
                    date: date,
                    notes: analysis.summary
                )
        }
        
        // Kayıt
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
            type: type,
            isProcessed: true
        )
        context.insert(newNote)
    }
    
    private func updateNoteWithAnalysis(
        note: VoiceNote,
        text: String,
        analysis: AIAnalysisResult
    ) {
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
        note.isProcessed = true
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        if let date = isoFormatter.date(from: dateString) { return date }
        
        // Yedek formatlar
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
}
