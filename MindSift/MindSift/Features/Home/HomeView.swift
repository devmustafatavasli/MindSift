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
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var allNotes: [VoiceNote]
    
    @StateObject private var audioManager = AudioManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var calendarManager = CalendarManager()
    
    private let geminiService = GeminiService()
    
    @State private var isAnalyzing = false
    @State private var showSettings = false
    
    @State private var searchText = ""
    @State private var selectedType: NoteType? = nil
    
    var filteredNotes: [VoiceNote] {
        allNotes.filter { note in
            let typeMatch = (selectedType == nil) || (note.type == selectedType)
            let textMatch = searchText.isEmpty ||
            (note.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (note.summary?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (
                note.transcription?
                    .localizedCaseInsensitiveContains(searchText) ?? false
            )
            return typeMatch && textMatch
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MeshBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                        .padding(.bottom, 10)
                    
                    if filteredNotes.isEmpty {
                        if !searchText.isEmpty || selectedType != nil {
                            noResultsView
                        } else {
                            emptyStateView
                        }
                    } else {
                        notesScrollView
                    }
                }
                
                floatingRecordingBar
                    .padding(.bottom, 20)
            }
            .navigationTitle("MindSift")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: audioManager.audioURL) { oldValue, newURL in
            if let url = newURL { processAudio(url: url) }
        }
        .onAppear {
            audioManager.checkPermissions()
            speechManager.checkPermissions()
        }
    }
    
    // MARK: - UI BİLEŞENLERİ
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Notlarda ara...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { withAnimation { searchText = "" } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(title: "Tümü", isSelected: selectedType == nil) {
                        withAnimation { selectedType = nil }
                    }
                    ForEach(NoteType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: selectedType == type
                        ) {
                            withAnimation { selectedType = type }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 120, height: 120)
                Image(systemName: "mic.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(DesignSystem.Gradients.primaryAction)
            }
            VStack(spacing: 8) {
                Text("Zihnin Çok mu Dolu?")
                    .font(DesignSystem.Typography.titleLarge())
                    .scaleEffect(0.8)
                    .foregroundStyle(.primary)
                Text(
                    "Mikrofona dokun ve aklındakileri boşalt.\nMindSift gerisini halleder."
                )
                .font(DesignSystem.Typography.body())
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Sonuç bulunamadı.")
                .font(DesignSystem.Typography.body())
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
    }
    
    private var notesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VoiceNoteCard(note: note)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button(role: .destructive) { deleteNote(note) } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    // 👇 GÜNCELLENMİŞ VE DÜZELTİLMİŞ KAYIT BUTONU
    private var floatingRecordingBar: some View {
        HStack {
            if audioManager.isRecording {
                Label("Kaydediliyor...", systemImage: "waveform")
                    .foregroundStyle(.white)
                    .font(DesignSystem.Typography.headline())
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else if isAnalyzing {
                Label("Süzülüyor...", systemImage: "sparkles")
                    .foregroundStyle(.white)
                    .font(DesignSystem.Typography.headline())
            } else {
                Text("Düşünceni Kaydet")
                    .foregroundStyle(.white.opacity(0.9))
                    .font(DesignSystem.Typography.headline())
            }
            
            Spacer()
            
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
                    // 1. BLOB ANIMASYONU (Artık Renkli ve Görünür)
                    if audioManager.isRecording {
                        PulsingBlob()
                    }
                    
                    // 2. ANA BUTON GÖVDESİ
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: DesignSystem.Effects.shadowMedium,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    // 3. İKON
                    if isAnalyzing {
                        ProgressView()
                            .tint(DesignSystem.Colors.primaryPurple)
                    } else {
                        Image(
                            systemName: audioManager.isRecording ? "stop.fill" : "mic.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            audioManager.isRecording ?
                            DesignSystem.Gradients.recordingAction :
                                DesignSystem.Gradients.primaryAction
                        )
                    }
                }
            }
            .disabled(isAnalyzing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 40)
        .padding(.horizontal)
        .scaleEffect(audioManager.isRecording ? 1.02 : 1.0)
    }
    
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
                                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"; f.locale = Locale(
                                    identifier: "en_US_POSIX"
                                )
                                eventDate = f.date(from: dateString)
                            }
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
                        
                        let newNote = VoiceNote(
                            audioFileName: url.lastPathComponent,
                            transcription: text,
                            title: analysis.title,
                            summary: analysis.summary,
                            priority: analysis.priority,
                            eventDate: eventDate,
                            emailSubject: analysis.email_subject,
                            emailBody: analysis.email_body,
                            type: type,
                            isProcessed: true
                        )
                        modelContext.insert(newNote)
                        
                    case .failure(let error):
                        print("Hata: \(error)")
                        let newNote = VoiceNote(
                            audioFileName: url.lastPathComponent,
                            transcription: text,
                            title: "Hata",
                            type: .unclassified
                        )
                        modelContext.insert(newNote)
                    }
                }
            }
        }
    }
    
    private func deleteNote(_ note: VoiceNote) {
        withAnimation { modelContext.delete(note) }
    }
}

// MARK: - YARDIMCI GÖRÜNÜMLER

// 👇 YENİLENMİŞ PULSING BLOB
struct PulsingBlob: View {
    @State private var animate = false
    
    var body: some View {
        Circle()
        // Beyaz yerine Kayıt Gradyanı kullanıyoruz, böylece "Glow" etkisi oluşuyor
            .fill(DesignSystem.Gradients.recordingAction)
            .frame(width: 60, height: 60) // Butonla aynı boyutta başla
            .scaleEffect(animate ? 2.0 : 1.0) // 2 katına kadar büyüt
            .opacity(animate ? 0.0 : 0.5) // Giderek kaybol
            .onAppear {
                animate = false // Sıfırla
                withAnimation(
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.subheadline())
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? DesignSystem.Colors.primaryBlue : Color.white
                        .opacity(0.5)
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.black.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
    }
}
