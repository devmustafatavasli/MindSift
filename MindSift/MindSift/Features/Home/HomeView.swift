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
    
    @StateObject private var audioManager = AudioManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var calendarManager = CalendarManager()
    private let geminiService = GeminiService()
    
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. ARKA PLAN (DesignSystem)
                DesignSystem.backgroundGradient.ignoresSafeArea()
                
                // 2. İÇERİK LİSTESİ
                if notes.isEmpty {
                    emptyStateView
                } else {
                    notesScrollView // Yeni Scroll Yapısı
                }
                
                // 3. YÜZEN KAYIT PANELİ (Floating Action Bar)
                floatingRecordingBar
                    .padding(.bottom, 20)
            }
            .navigationTitle("MindSift")
            .navigationBarTitleDisplayMode(.large)
        }
        // Kayıt Bitiş Olayı
        .onChange(of: audioManager.audioURL) { oldValue, newURL in
            if let url = newURL { processAudio(url: url) }
        }
        .onAppear {
            audioManager.checkPermissions()
            speechManager.checkPermissions()
        }
    }
    
    // MARK: - YENİ UI BİLEŞENLERİ
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 120, height: 120)
                Image(systemName: "mic.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(DesignSystem.primaryGradient)
            }
            
            VStack(spacing: 8) {
                Text("Zihnin Çok mu Dolu?")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(
                    "Mikrofona dokun ve aklındakileri boşalt.\nMindSift gerisini halleder."
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
    }
    
    private var notesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(notes) { note in
                    // Her kartı Detay sayfasına yönlendiriyoruz
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VoiceNoteCard(note: note)
                    }
                    .buttonStyle(
                        PlainButtonStyle()
                    ) // Linkin mavi renge dönüşmesini engeller
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteNote(note)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 100) // Yüzen butonun altında içerik kalmasın
        }
    }
    
    private var floatingRecordingBar: some View {
        HStack {
            if audioManager.isRecording {
                Label("Dinliyorum...", systemImage: "waveform")
                    .foregroundStyle(.white)
                    .font(.system(.headline, design: .rounded))
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else if isAnalyzing {
                Label("AI Düşünüyor...", systemImage: "sparkles")
                    .foregroundStyle(.white)
                    .font(.system(.headline, design: .rounded))
            } else {
                Text("Dokun ve Kaydet")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.system(.subheadline, design: .rounded))
            }
            
            Spacer()
            
            // Kayıt Butonu (Animasyonlu)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    if audioManager.isRecording {
                        audioManager.stopRecording()
                    } else {
                        audioManager.startRecording()
                    }
                }
            } label: {
                ZStack {
                    if audioManager.isRecording {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    } else if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(width: 56, height: 56)
                .background {
                    if audioManager.isRecording {
                        Circle().fill(Color.red)
                    } else {
                        Circle().fill(DesignSystem.primaryGradient)
                    }
                }
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isAnalyzing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial) // Glass effect
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal)
        .scaleEffect(audioManager.isRecording ? 1.05 : 1.0)
    }
    
    // MARK: - Mantık Fonksiyonları
    
    private func processAudio(url: URL) {
        speechManager.transcribeAudio(url: url) { text in
            guard let text = text, !text.isEmpty else { return }
            
            withAnimation { isAnalyzing = true }
            
            geminiService.analyzeText(text: text) { result in
                DispatchQueue.main.async {
                    withAnimation { isAnalyzing = false }
                    
                    switch result {
                    case .success(let analysis):
                        let type = NoteType(
                            rawValue: analysis.type
                        ) ?? .unclassified
                        
                        var eventDate: Date? = nil
                        if let dateString = analysis.event_date {
                            let isoFormatter = ISO8601DateFormatter()
                            isoFormatter.formatOptions = [
                                .withInternetDateTime,
                                .withFractionalSeconds
                            ]
                            eventDate = isoFormatter.date(from: dateString)
                            
                            if eventDate == nil {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                                formatter.locale = Locale(
                                    identifier: "en_US_POSIX"
                                )
                                eventDate = formatter.date(from: dateString)
                            }
                            
                            if let date = eventDate, (
                                type == .meeting || type == .task
                            ) {
                                calendarManager
                                    .addEvent(
                                        title: analysis.title,
                                        date: date,
                                        notes: analysis.summary
                                    )
                            }
                        }
                        
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
                        print("Hata: \(error)")
                        let newNote = VoiceNote(
                            audioFileName: url.lastPathComponent,
                            transcription: text,
                            title: "Hata: Not Analiz Edilemedi",
                            type: .unclassified
                        )
                        modelContext.insert(newNote)
                    }
                }
            }
        }
    }
    
    private func deleteNote(_ note: VoiceNote) {
        withAnimation {
            modelContext.delete(note)
        }
    }
}

