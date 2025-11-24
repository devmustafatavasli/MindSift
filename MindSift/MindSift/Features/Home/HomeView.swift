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
    
    // API Servisi (Stateless olduğu için @StateObject gerekmez)
    private let geminiService = GeminiService()
    
    // Yükleniyor durumu (Analiz yapılırken ekranda göstermek için)
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
        // KAYIT BİTTİĞİNDE TETİKLENİR
        .onChange(of: audioManager.audioURL) { oldValue, newURL in
            if let url = newURL {
                processAudio(url: url)
            }
        }
        .onAppear {
            audioManager.checkPermissions()
            speechManager.checkPermissions()
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
                    // İkon ve Öncelik Göstergesi
                    VStack {
                        Image(systemName: note.type.iconName)
                            .foregroundStyle(.blue)
                            .frame(width: 30, height: 30)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        // Eğer öncelik Yüksek ise ünlem göster
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
                        
                        Text(note.createdAt.formatted(date: .numeric, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
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
            // Durum Metinleri
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
                        .fill(audioManager.isRecording ? Color.red : (isAnalyzing ? Color.purple : Color.blue))
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                    
                    // Yükleniyor Animasyonu veya Mikrofon İkonu
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(speechManager.isTranscribing || isAnalyzing)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - MANTIK MERKEZİ (AI INTEGRATION) 🧠
    
    private func processAudio(url: URL) {
        // 1. Sesi Yazıya Çevir
        speechManager.transcribeAudio(url: url) { text in
            guard let text = text, !text.isEmpty else {
                print("Ses anlaşılamadı.")
                return
            }
            
            // UI'da "Analiz ediliyor" göster
            self.isAnalyzing = true
            
            // 2. Gemini ile Analiz Et
            geminiService.analyzeText(text: text) { result in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    
                    switch result {
                    case .success(let analysis):
                        // 3. Başarılı Analizi Kaydet
                        // Gelen string tipi Enum'a çevir (Eşleşmezse 'Genel' yap)
                        let type = NoteType(rawValue: analysis.type) ?? .unclassified
                        
                        let newNote = VoiceNote(
                            audioFileName: url.lastPathComponent,
                            transcription: text,
                            title: analysis.title,
                            summary: analysis.summary,
                            priority: analysis.priority,
                            type: type,
                            isProcessed: true
                        )
                        modelContext.insert(newNote)
                        
                    case .failure(let error):
                        // Hata olsa bile notu ham haliyle kaydet (Veri kaybı olmasın)
                        print("AI Hatası: \(error.localizedDescription)")
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
