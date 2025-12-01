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
    
    // Arama ve Filtre
    @State private var searchText = ""
    @State private var selectedType: NoteType? = nil
    
    // 👇 YENİ: Harita Modu için Sheet Kontrolü
    @State private var showMindMap = false
    
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
                // 1. ARKA PLAN
                MeshBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 2. ÜST KISIM
                    headerSection
                        .padding(.bottom, 10)
                    
                    // 3. İÇERİK LİSTESİ (Sadece Liste Görünümü)
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
                
                // 4. YÜZEN KAYIT PANELİ
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
        // 👇 YENİ: Mind Map Tam Ekran Açılır
        .fullScreenCover(isPresented: $showMindMap) {
            MindMapSheetView(notes: filteredNotes)
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
            HStack(spacing: 12) {
                // Arama Kutusu
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
                
                // 👇 YENİ: Harita Açma Butonu
                Button {
                    showMindMap = true
                } label: {
                    Image(systemName: "network") // Zihin haritası ikonu
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            
            // Filtreler
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
            Spacer(); Spacer()
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
            Spacer(); Spacer()
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
            .padding().padding(.bottom, 100)
        }
    }
    
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
                    if audioManager.isRecording { audioManager.stopRecording() } else {
                        audioManager.startRecording()
                    }
                }
            } label: {
                ZStack {
                    if audioManager.isRecording { PulsingBlob() }
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: DesignSystem.Effects.shadowMedium,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    if isAnalyzing {
                        ProgressView().tint(DesignSystem.Colors.primaryPurple)
                    } else {
                        Image(
                            systemName: audioManager.isRecording ? "stop.fill" : "mic.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            audioManager.isRecording ? DesignSystem.Gradients.recordingAction : DesignSystem.Gradients.primaryAction
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
                            smartIcon: analysis.suggested_icon,
                            smartColor: analysis.suggested_color,
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

// MARK: - YENİ MIND MAP SHEET (Tam Ekran Modu)
struct MindMapSheetView: View {
    let notes: [VoiceNote]
    @Environment(\.dismiss) var dismiss
    
    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @State private var currentDragOffset: CGSize = .zero
    @State private var currentMagnification: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Arka Plan (Aynı tutarlılık için)
            MeshBackground().ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    // Harita Tuvali
                    MindMapView(notes: notes)
                        .frame(width: 1500, height: 1500)
                        .contentShape(
                            Rectangle()
                        ) // Boşlukları sürüklenebilir yap
                        .scaleEffect(mapScale * currentMagnification)
                        .offset(
                            x: mapOffset.width + currentDragOffset.width,
                            y: mapOffset.height + currentDragOffset.height
                        )
                        .position(
                            x: geo.size.width / 2,
                            y: geo.size.height / 2
                        ) // Merkeze sabitle
                        .gesture(
                            DragGesture()
                                .onChanged {
                                    val in currentDragOffset = val.translation
                                }
                                .onEnded { val in
                                    mapOffset.width += val.translation.width
                                    mapOffset.height += val.translation.height
                                    currentDragOffset = .zero
                                }
                        )
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { val in currentMagnification = val }
                                .onEnded { val in
                                    mapScale *= val
                                    currentMagnification = 1.0
                                }
                        )
                }
            }
            
            // ÜST BAR (Kapat Butonu)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                Spacer()
            }
            
            // ALT KONTROLLER
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    mapControls
                        .padding(.trailing, 20)
                        .padding(.bottom, 50)
                }
            }
        }
    }
    
    private var mapControls: some View {
        VStack(spacing: 12) {
            Button(
                action: { withAnimation { mapScale = min(mapScale + 0.5, 3.0) }
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            Button(
                action: { withAnimation(.spring()) {
                    mapScale = 1.0; mapOffset = .zero
                }
                }) {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .foregroundStyle(.blue)
                }
            Button(
                action: { withAnimation { mapScale = max(mapScale - 0.5, 0.5) }
                }) {
                    Image(systemName: "minus")
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - YARDIMCI VIEW'LAR
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

struct PulsingBlob: View {
    @State private var animate = false
    var body: some View {
        Circle()
            .fill(DesignSystem.Gradients.recordingAction)
            .frame(width: 60, height: 60)
            .scaleEffect(animate ? 2.0 : 1.0)
            .opacity(animate ? 0.0 : 0.5)
            .onAppear {
                animate = false
                withAnimation(
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}
