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
    // Tüm notları çekiyoruz (Filtrelemeyi memory'de yapacağız, MVP için en akıcı yöntem)
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var allNotes: [VoiceNote]
    
    // Yöneticiler
    @StateObject private var audioManager = AudioManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var calendarManager = CalendarManager()
    private let geminiService = GeminiService()
    
    // UI Durumları
    @State private var isAnalyzing = false
    @State private var showSettings = false
    
    // 🔍 ARAMA VE FİLTRE DURUMLARI
    @State private var searchText = ""
    @State private var selectedType: NoteType? = nil // nil = Hepsi
    
    // 🧠 FİLTRELENMİŞ LİSTE (Computed Property)
    var filteredNotes: [VoiceNote] {
        allNotes.filter { note in
            // 1. Kategori Filtresi
            let typeMatch = (selectedType == nil) || (note.type == selectedType)
            
            // 2. Metin Araması (Başlık, Özet veya İçerik)
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
                // 1. ARKA PLAN
                DesignSystem.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 2. ARAMA VE FİLTRE ALANI (YENİ)
                    headerSection
                        .padding(.bottom, 10)
                    
                    // 3. İÇERİK
                    if filteredNotes.isEmpty {
                        if !searchText.isEmpty || selectedType != nil {
                            noResultsView // Arama sonucu boşsa
                        } else {
                            emptyStateView // Hiç not yoksa
                        }
                    } else {
                        notesScrollView
                    }
                }
                
                // 4. YÜZEN KAYIT PANELİ
                floatingRecordingBar
                    .padding(.bottom, 20)
            }
            .navigationTitle("MindSift")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
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
    
    // MARK: - UI Bileşenleri
    
    // 👇 YENİ: Üst Kısım (Arama + Filtreler)
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Arama Çubuğu
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Notlarda ara...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        withAnimation { searchText = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            // Kategori Filtreleri (Yatay Kaydırma)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // "Tümü" Butonu
                    FilterChip(title: "Tümü", isSelected: selectedType == nil) {
                        withAnimation { selectedType = nil }
                    }
                    
                    // Diğer Kategoriler
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
        .background(
            DesignSystem.backgroundGradient.opacity(0.9)
        ) // Hafif background
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
    
    // Arama sonucu bulunamazsa
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Sonuç bulunamadı.")
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
    }
    
    private var notesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Filtrelenmiş listeyi kullanıyoruz
                ForEach(filteredNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VoiceNoteCard(note: note)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            .padding(.bottom, 100)
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
                    .foregroundStyle(AnyShapeStyle(DesignSystem.primaryGradient).opacity(0.8))
                    .font(.system(.subheadline, design: .rounded))
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
                .background(
                    audioManager.isRecording ? AnyShapeStyle(Color.red) : AnyShapeStyle(
                        DesignSystem.primaryGradient
                    )
                )
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isAnalyzing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal)
        .scaleEffect(audioManager.isRecording ? 1.05 : 1.0)
    }
    
    // MARK: - Mantık
    
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
                            // Tarih formatlama mantığı (öncekiyle aynı)
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
                            
                            // Yedek formatlar
                            if eventDate == nil {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                                formatter.locale = Locale(
                                    identifier: "en_US_POSIX"
                                )
                                eventDate = formatter.date(from: dateString)
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
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredNotes[index])
            }
        }
    }
}

// MARK: - YARDIMCI VIEW (Filtre Butonu)
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
    }
}
