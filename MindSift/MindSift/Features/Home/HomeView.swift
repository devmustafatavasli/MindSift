//
//  HomeView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // Veritabanı ve Query View tarafında kalır (SwiftUI'ın reaktif yapısı için en doğrusu)
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var allNotes: [VoiceNote]
    
    // 👇 TEK KAYNAK: Tüm mantık ve durumlar burada
    @StateObject private var viewModel = HomeViewModel()
    
    // Filtrelenmiş Liste (Logic: View'da kalabilir çünkü @Query'ye bağlı)
    var filteredNotes: [VoiceNote] {
        allNotes.filter { note in
            let typeMatch = (viewModel.selectedType == nil) || (
                note.type == viewModel.selectedType
            )
            
            let textMatch = viewModel.searchText.isEmpty ||
            (note.title?.localizedCaseInsensitiveContains(viewModel.searchText) ?? false) ||
            (note.summary?.localizedCaseInsensitiveContains(viewModel.searchText) ?? false) ||
            (
                note.transcription?
                    .localizedCaseInsensitiveContains(
                        viewModel.searchText
                    ) ?? false
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
                    // 2. ÜST KISIM (Arama ve Filtreler)
                    headerSection
                        .padding(.bottom, 10)
                    
                    // 3. İÇERİK LİSTESİ
                    if filteredNotes.isEmpty {
                        if !viewModel.searchText.isEmpty || viewModel.selectedType != nil {
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
            .navigationTitle(AppConstants.Texts.appName)
            .navigationBarTitleDisplayMode(.large)
            
            // AYARLAR BUTONU
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: AppConstants.Icons.gear)
                            .foregroundStyle(DesignSystem.Colors.primaryBlue)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
        // TAM EKRAN HARİTA MODU
        .fullScreenCover(isPresented: $viewModel.showMindMap) {
            MindMapSheetView(notes: filteredNotes)
        }
        // AYARLAR SAYFASI
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        // KAYIT BİTİNCE ÇALIŞIR
        .onChange(of: viewModel.audioManager.audioURL) { oldValue, newURL in
            if let url = newURL {
                viewModel.processAudio(url: url, context: modelContext)
            }
        }
        // DIŞARIDAN TETİKLEME (URL SCHEME)
        .onOpenURL { url in
            viewModel.handleDeepLink(url: url)
        }
        // AÇILIŞ İŞLEMLERİ
        .onAppear {
            // Share Extension'dan gelenleri işle
            viewModel.processPendingNotes(allNotes: allNotes)
        }
        // İNTERNET UYARISI
        .alert("Bağlantı Hatası", isPresented: $viewModel.showNetworkAlert) {
            Button(AppConstants.Texts.Actions.ok, role: .cancel) { }
        } message: {
            Text(viewModel.networkErrorMessage)
        }
    }
    
    // MARK: - UI BİLEŞENLERİ
    
    // Arama Çubuğu ve Filtreler
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Arama Çubuğu ve Harita Butonu
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: AppConstants.Icons.magnifyingGlass)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    TextField(
                        AppConstants.Texts.Home.searchPlaceholder,
                        text: $viewModel.searchText
                    )
                    .textFieldStyle(.plain)
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            withAnimation { viewModel.searchText = "" }
                        } label: {
                            Image(systemName: AppConstants.Icons.xmarkCircle)
                                .foregroundStyle(
                                    DesignSystem.Colors.textSecondary
                                )
                        }
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Harita Açma Butonu
                Button {
                    viewModel.showMindMap = true
                } label: {
                    Image(systemName: AppConstants.Icons.network)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            
            // Kategori Çipleri
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(
                        title: "Tümü",
                        isSelected: viewModel.selectedType == nil
                    ) {
                        withAnimation { viewModel.selectedType = nil }
                    }
                    
                    ForEach(NoteType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: viewModel.selectedType == type
                        ) {
                            withAnimation { viewModel.selectedType = type }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }
    
    // Boş Durum
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryBlue.opacity(0.05))
                    .frame(width: 120, height: 120)
                Image(systemName: AppConstants.Icons.micFill)
                    .font(.system(size: 50))
                    .foregroundStyle(DesignSystem.Gradients.primaryAction)
            }
            
            VStack(spacing: 8) {
                Text(AppConstants.Texts.Home.emptyTitle)
                    .font(DesignSystem.Typography.titleLarge())
                    .scaleEffect(0.8)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(AppConstants.Texts.Home.emptySubtitle)
                    .font(DesignSystem.Typography.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
    }
    
    // Sonuç Bulunamadı
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: AppConstants.Icons.magnifyingGlass)
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(AppConstants.Texts.Home.noResults)
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Spacer()
        }
    }
    
    // Not Listesi
    private var notesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredNotes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VoiceNoteCard(note: note)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteNote(note, context: modelContext)
                        } label: {
                            Label(
                                AppConstants.Texts.Actions.delete,
                                systemImage: AppConstants.Icons.trash
                            )
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    // Yüzen Kayıt Paneli
    private var floatingRecordingBar: some View {
        HStack {
            if viewModel.audioManager.isRecording {
                Label(
                    AppConstants.Texts.Home.recordingState,
                    systemImage: AppConstants.Icons.waveform
                )
                .foregroundStyle(.white)
                .font(DesignSystem.Typography.headline())
                .transition(.move(edge: .leading).combined(with: .opacity))
            } else if viewModel.isAnalyzing {
                Label(
                    AppConstants.Texts.Home.analyzingState,
                    systemImage: AppConstants.Icons.sparkles
                )
                .foregroundStyle(.white)
                .font(DesignSystem.Typography.headline())
            } else {
                Text(AppConstants.Texts.Home.idleState)
                    .foregroundStyle(.white.opacity(0.9))
                    .font(DesignSystem.Typography.headline())
            }
            
            Spacer()
            
            Button {
                withAnimation(
                    .spring(
                        response: AppConstants.Animation.springResponse,
                        dampingFraction: AppConstants.Animation.springDamping
                    )
                ) {
                    if viewModel.audioManager.isRecording {
                        viewModel.audioManager.stopRecording()
                    } else {
                        viewModel.audioManager.startRecording()
                    }
                }
            } label: {
                ZStack {
                    if viewModel.audioManager.isRecording {
                        PulsingBlob()
                    }
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: DesignSystem.Effects.shadowMedium,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .tint(DesignSystem.Colors.primaryPurple)
                    } else {
                        Image(
                            systemName: viewModel.audioManager.isRecording ? AppConstants.Icons.stopFill : AppConstants.Icons.micFill
                        )
                        .font(.title2)
                        .foregroundStyle(
                            viewModel.audioManager.isRecording ?
                            DesignSystem.Gradients.recordingAction :
                                DesignSystem.Gradients.primaryAction
                        )
                    }
                }
            }
            .disabled(viewModel.isAnalyzing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 40)
        .padding(.horizontal)
        .scaleEffect(viewModel.audioManager.isRecording ? 1.02 : 1.0)
    }
}

// MARK: - YARDIMCI BİLEŞENLER

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
                    isSelected ?
                    DesignSystem.Colors.primaryBlue :
                        Color.white.opacity(0.5)
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
                    .easeOut(duration: AppConstants.Animation.blobDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}

struct MindMapSheetView: View {
    let notes: [VoiceNote]
    @Environment(\.dismiss) var dismiss
    
    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @State private var currentDragOffset: CGSize = .zero
    @State private var currentMagnification: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            MeshBackground().ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    MindMapView(notes: notes)
                        .frame(width: 1500, height: 1500)
                        .contentShape(Rectangle())
                        .scaleEffect(mapScale * currentMagnification)
                        .offset(
                            x: mapOffset.width + currentDragOffset.width,
                            y: mapOffset.height + currentDragOffset.height
                        )
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
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
            
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: AppConstants.Icons.xmarkCircle)
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                Spacer()
            }
            
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
                    Image(systemName: AppConstants.Icons.plus)
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
                    Image(systemName: AppConstants.Icons.location)
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .foregroundStyle(DesignSystem.Colors.primaryBlue)
                }
            Button(
                action: { withAnimation { mapScale = max(mapScale - 0.5, 0.5) }
                }) {
                    Image(systemName: AppConstants.Icons.minus)
                        .font(.title3)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
        }
        .foregroundStyle(DesignSystem.Colors.textPrimary)
    }
}
