//
//  HomeView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]
    
    // Yöneticiler
    @StateObject private var audioManager = AudioManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var calendarManager = CalendarManager()
    
    // API Servisi
    private let geminiService = GeminiService()
    
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    if notes.isEmpty {
                        emptyStateView
                    } else {
                        notesListView
                    }
                    
                    Spacer()
                    
                    recordingSection
                }
            }
            .navigationTitle("MindSift")
        }
        .onChange(of: audioManager.audioURL) { oldValue, newURL in
            if let url = newURL {
                processAudio(url: url)
            }
        }
        .onAppear {
            audioManager.checkPermissions()
            speechManager.checkPermissions()
            // CalendarManager zaten init içinde izin istiyor
        }
    }
    
    // MARK: - Görünümler
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "mic.circle")
                .font(.system(size: 80))
                .foregroundStyle(.gray.opacity(0.5))
            Text("Aklındakileri dök.\nMindSift onları düzenler.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            Spacer()
        }
    }
    
    private var notesListView: some View {
        List {
            ForEach(notes) { note in
                HStack(alignment: .top) {
                    VStack {
                        Image(systemName: note.type.iconName)
                            .foregroundStyle(.blue)
                            .frame(width: 30, height: 30)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        if let priority = note.priority, priority == "Yüksek" {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title ?? "İsimsiz")
                            .font(.headline)
                        
                        if let summary = note.summary {
                            Text(summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        if let eventDate = note.eventDate {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(
                                    eventDate
                                        .formatted(
                                            date: .numeric,
                                            time: .shortened
                                        )
                                )
                                .font(.caption)
                            }
                            .foregroundStyle(.blue)
                            .padding(.top, 2)
                        } else {
                            Text(
                                note.createdAt
                                    .formatted(date: .numeric, time: .shortened)
                            )
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteNotes)
        }
        .scrollContentBackground(.hidden)
    }
    
    private var recordingSection: some View {
        VStack {
            if audioManager.isRecording {
                Text("Dinliyorum...")
                    .foregroundStyle(.red)
            } else if speechManager.isTranscribing {
                Text("Yazıya dökülüyor...")
                    .foregroundStyle(.orange)
            } else if isAnalyzing {
                Text("AI Analiz Ediyor...")
                    .foregroundStyle(.purple)
            }
            
            Button {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                } else {
                    audioManager.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            audioManager.isRecording ? Color.red : (
                                isAnalyzing ? Color.purple : Color.blue
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                    
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(
                            systemName: audioManager.isRecording ? "stop.fill" : "mic.fill"
                        )
                        .font(.title)
                        .foregroundStyle(.white)
                    }
                }
            }
            .disabled(speechManager.isTranscribing || isAnalyzing)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - MANTIK MERKEZİ 🧠
    
    private func processAudio(url: URL) {
        speechManager.transcribeAudio(url: url) { text in
            guard let text = text, !text.isEmpty else { return }
            
            self.isAnalyzing = true
            
            geminiService.analyzeText(text: text) { result in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    
                    switch result {
                    case .success(let analysis):
                        print("🔍 DEBUG: AI Yanıtı Geldi")
                        print("   - Tip: \(analysis.type)")
                        print(
                            "   - Tarih String: \(analysis.event_date ?? "YOK")"
                        )
                        
                        let type = NoteType(
                            rawValue: analysis.type
                        ) ?? .unclassified
                        
                        // --- GÜÇLENDİRİLMİŞ TARİH AYIKLAMA (GÜNCEL) ---
                        var eventDate: Date? = nil
                        
                        if let dateString = analysis.event_date {
                            // 1. Yöntem: Standart ISO (2024-11-25T14:00:00Z) - Z harfi olan
                            let isoFormatter = ISO8601DateFormatter()
                            isoFormatter.formatOptions = [
                                .withInternetDateTime,
                                .withFractionalSeconds
                            ]
                            eventDate = isoFormatter.date(from: dateString)
                            
                            // 2. Yöntem: Basit ISO (Z olmadan) - 2024-11-25T14:00:00
                            if eventDate == nil {
                                let simpleISO = ISO8601DateFormatter()
                                simpleISO.formatOptions = [.withInternetDateTime] // Bazen Z'siz de çalışır
                                eventDate = simpleISO.date(from: dateString)
                            }
                            
                            // 3. Yöntem: BİZİM İHTİYACIMIZ OLAN (T var, Z yok, Saniye var)
                            // Örn: 2025-11-25T16:00:00
                            if eventDate == nil {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                                formatter.locale = Locale(
                                    identifier: "en_US_POSIX"
                                )
                                eventDate = formatter.date(from: dateString)
                            }
                            
                            // 4. Yöntem: Saniyesiz T'li (2025-11-25T16:00)
                            if eventDate == nil {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                                formatter.locale = Locale(
                                    identifier: "en_US_POSIX"
                                )
                                eventDate = formatter.date(from: dateString)
                            }
                            
                            // 5. Yöntem: Düz Format (2025-11-25 16:00)
                            if eventDate == nil {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                                formatter.locale = Locale(
                                    identifier: "en_US_POSIX"
                                )
                                eventDate = formatter.date(from: dateString)
                            }
                        }
                        
                        print(
                            "   - Date Obj: \(eventDate != nil ? "BAŞARILI ✅" : "BAŞARISIZ ❌")"
                        )
                        
                        // --- TAKVİME EKLEME ---
                        if let date = eventDate, (
                            type == .meeting || type == .task
                        ) {
                            print("   - Takvime ekleme komutu gönderiliyor...")
                            calendarManager.addEvent(
                                title: analysis.title,
                                date: date,
                                notes: analysis.summary
                            )
                        } else {
                            print(
                                "   - Takvim atlandı. (Tarih yok veya Tip uymuyor)"
                            )
                        }
                        
                        // Notu Kaydet
                        let newNote = VoiceNote(
                            audioFileName: url.lastPathComponent,
                            transcription: text,
                            title: analysis.title,
                            summary: analysis.summary,
                            priority: analysis.priority,
                            eventDate: eventDate,
                            type: type,
                            isProcessed: true
                        )
                        modelContext.insert(newNote)
                        
                    case .failure(let error):
                        print("❌ AI Hatası: \(error.localizedDescription)")
                        let newNote = VoiceNote(
                            audioFileName: url.lastPathComponent,
                            transcription: text,
                            title: text.prefix(20) + "...",
                            type: .unclassified
                        )
                        modelContext.insert(newNote)
                    }
                }
            }
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(notes[index])
            }
        }
    }
}
