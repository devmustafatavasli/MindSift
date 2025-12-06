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
    
    @StateObject private var viewModel = HomeViewModel()
    
    // Eski "computed property" filteredNotes silindi.
    // Artık viewModel.filteredNotes kullanılıyor.
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MeshBackground().ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection.padding(.bottom, 10)
                    
                    // 3. İÇERİK LİSTESİ (Kaynaktan Değişiklik: viewModel.filteredNotes)
                    if viewModel.filteredNotes.isEmpty {
                        if !viewModel.searchText.isEmpty || viewModel.selectedType != nil {
                            noResultsView
                        } else {
                            emptyStateView
                        }
                    } else {
                        notesScrollView
                    }
                }
                
                floatingRecordingBar.padding(.bottom, 20)
            }
            .navigationTitle(AppConstants.Texts.appName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        // 🧪 TEST BUTONU (Sadece Debug modunda veya Simülatörde görünsün)
                        Button {
                            viewModel
                                .debugSimulateRecording(context: modelContext)
                        } label: {
                            Image(systemName: "bolt.fill") // Şimşek ikonu
                                .foregroundStyle(.yellow)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                                    
                        // MEVCUT AYARLAR BUTONU
                        Button {
                            viewModel.showSettings = true
                        } label: {
                            Image(systemName: AppConstants.Icons.gear)
                                .foregroundStyle(
                                    DesignSystem.Colors.primaryBlue
                                )
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showMindMap) {
            MindMapSheetView(
                notes: viewModel.filteredNotes
            ) // Haritaya da filtrelenmişleri veriyoruz
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        .onChange(of: viewModel.audioManager.audioURL) { oldValue, newURL in
            if let url = newURL {
                viewModel.processAudio(url: url, context: modelContext)
            }
        }
        .onOpenURL { url in viewModel.handleDeepLink(url: url) }
        .onAppear {
            viewModel.processPendingNotes(allNotes: allNotes)
            // Sayfa açılınca aramayı başlat (Tüm notları gösterir)
            viewModel.triggerSearch(with: allNotes)
        }
        // 👇 TETİKLEYİCİLER: Veri değiştiğinde aramayı yenile
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.triggerSearch(with: allNotes)
        }
        .onChange(of: viewModel.selectedType) { _, _ in
            viewModel.triggerSearch(with: allNotes)
        }
        .onChange(of: allNotes) { _, newNotes in
            print("🔄 Veritabanı değişti: \(newNotes.count) not bulundu.")
            viewModel.triggerSearch(with: newNotes)
        }
        .alert("Bağlantı Hatası", isPresented: $viewModel.showNetworkAlert) {
            Button(AppConstants.Texts.Actions.ok, role: .cancel) { }
        } message: {
            Text(viewModel.networkErrorMessage)
        }
    }
    
    // MARK: - UI BİLEŞENLERİ
    
    private var headerSection: some View {
        VStack(spacing: 12) {
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
    
    private var notesScrollView: some View {
        ScrollView {
            // DİKKAT: Burada filteredNotes yerine viewModel.filteredNotes kullanılıyor
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredNotes) { note in
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

// Yardımcı bileşenler (FilterChip, PulsingBlob, MindMapSheetView)
// aynı kaldığı için buraya tekrar kopyalamadım, onları değiştirme.
// Eğer dosyanın tamamını değiştireceksen eski dosyadaki o alt kısımları (class bittikten sonraki kısımları)
// kopyalayıp buraya eklemeyi unutma.

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
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        Circle()
            .fill(DesignSystem.Gradients.recordingAction)
            .frame(width: 60, height: 60)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    scale = 2.5
                    opacity = 0.0
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
        // 👇 DÜZELTME 1: NavigationStack eklendi. Linkler artık çalışacak.
        NavigationStack {
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
                            .position(
                                x: geo.size.width / 2,
                                y: geo.size.height / 2
                            )
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
                                    .onChanged {
                                        val in currentMagnification = val
                                    }
                                    .onEnded { val in
                                        mapScale *= val
                                        currentMagnification = 1.0
                                    }
                            )
                    }
                }
                
                // Kapatma Butonu
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
                
                // Kontrol Butonları
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
            // Navigation Bar'ı gizle ki tam ekran deneyimi bozulmasın
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // ... (mapControls aynı kalıyor) ...
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
