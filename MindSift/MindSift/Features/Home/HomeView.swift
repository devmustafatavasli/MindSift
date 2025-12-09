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
    
    @State private var viewModel = HomeViewModel()
    
    // Arama ve Animasyon Durumları
    @State private var isSearchExpanded: Bool = false
    @Namespace private var animationNamespace
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. KATMAN: Arka Plan
                MeshBackground()
                    .ignoresSafeArea()
                
                // 2. KATMAN: Ana Yapı (Header + Liste)
                VStack(spacing: 0) {
                    
                    // A. DİNAMİK HEADER (Safe Area ile otomatik uyumlu)
                    // VStack'in en tepesinde olduğu için SwiftUI bunu çentiğin altına iter.
                    dynamicHeader
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .zIndex(2) // Animasyonlarda üstte kalsın
                    
                    // B. İÇERİK ALANI (Scroll)
                    ScrollView {
                        if viewModel.filteredNotes.isEmpty {
                            if !viewModel.searchText.isEmpty || viewModel.selectedType != nil {
                                noResultsView.padding(.top, 80)
                            } else {
                                emptyStateView.padding(.top, 80)
                            }
                        } else {
                            MasonryVStack(
                                columns: 2,
                                spacing: 12,
                                items: viewModel.filteredNotes
                            ) { note in
                                NavigationLink(
                                    destination: NoteDetailView(note: note)
                                ) {
                                    VoiceNoteCard(note: note)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button {
                                        withAnimation {
                                            note.isFavorite.toggle()
                                        }
                                    } label: {
                                        Label(
                                            note.isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                                            systemImage: note.isFavorite ? "heart.slash" : "heart"
                                        )
                                    }
                                    Button { } label: {
                                        Label(
                                            "Paylaş",
                                            systemImage: "square.and.arrow.up"
                                        )
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        withAnimation {
                                            viewModel
                                                .deleteNote(
                                                    note,
                                                    context: modelContext
                                                )
                                        }
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 120) // Kayıt butonu payı
                        }
                    }
                    .scrollIndicators(.hidden)
                }
                
                // 3. KATMAN: Yüzen Kayıt Butonu
                floatingRecordingBar
                    .padding(.bottom, 20)
                    .zIndex(3)
            }
            // Native Navigation Bar'ı gizle, kendi header'ımızı kullanıyoruz
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $viewModel.showMindMap) {
            MindMapSheetView(notes: viewModel.filteredNotes)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        .onChange(of: viewModel.audioManager.audioURL) {
 oldValue,
            newURL in
            if let url = newURL {
                viewModel.processAudio(url: url, context: modelContext)
            }
        }
        .onOpenURL { url in viewModel.handleDeepLink(url: url) }
        .onAppear {
            viewModel.processPendingNotes()
            viewModel.triggerSearch(with: allNotes)
        }
        .onChange(of: viewModel.searchText) {
            _,
            _ in viewModel.triggerSearch(with: allNotes)
        }
        .onChange(of: viewModel.selectedType) {
            _,
            _ in viewModel.triggerSearch(with: allNotes)
        }
        .onChange(of: allNotes) {
            _,
            newNotes in viewModel.triggerSearch(with: newNotes)
        }
        .alert("Bağlantı Hatası", isPresented: $viewModel.showNetworkAlert) {
            Button(AppConstants.Texts.Actions.ok, role: .cancel) { }
        } message: {
            Text(viewModel.networkErrorMessage)
        }
    }
    
    // MARK: - DİNAMİK HEADER (SİMETRİK VE GÜVENLİ)
    
    private var dynamicHeader: some View {
        VStack(spacing: 0) {
            ZStack {
                // KATMAN 1: Sağ Üst Butonlar (MindMap & Ayarlar)
                if !isSearchExpanded {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Button {
                                viewModel.showMindMap = true
                            } label: {
                                Image(systemName: AppConstants.Icons.network)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(
                                        DesignSystem.Colors.primaryBlue
                                    )
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(
                                        color: Color.black.opacity(0.05),
                                        radius: 5
                                    )
                            }
                            
                            Button {
                                viewModel.showSettings = true
                            } label: {
                                Image(systemName: AppConstants.Icons.gear)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.gray)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(
                                        color: Color.black.opacity(0.05),
                                        radius: 5
                                    )
                            }
                        }
                        .padding(.trailing, 16)
                        .transition(.opacity)
                    }
                }
                
                // KATMAN 2: Ortadaki Arama/Logo Kapsülü (Dinamik Ada)
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(
                            color: Color.black.opacity(0.08),
                            radius: 10,
                            x: 0,
                            y: 4
                        )
                    
                    if isSearchExpanded {
                        // AÇIK MOD
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            
                            TextField(
                                "Notlarda ara...",
                                text: $viewModel.searchText
                            )
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .medium))
                            .matchedGeometryEffect(
                                id: "TitleText",
                                in: animationNamespace
                            )
                            
                            // Kapat Butonu (X)
                            Button {
                                withAnimation(
                                    .spring(response: 0.3, dampingFraction: 0.7)
                                ) {
                                    isSearchExpanded = false
                                    viewModel.searchText = ""
                                    viewModel.selectedType = nil
                                    UIApplication.shared
                                        .sendAction(
                                            #selector(
                                                UIResponder.resignFirstResponder
                                            ),
                                            to: nil,
                                            from: nil,
                                            for: nil
                                        )
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                        
                    } else {
                        // KAPALI MOD
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(
                                    DesignSystem.Gradients.primaryAction
                                )
                            
                            Text("MindSift")
                                .font(
                                    .system(
                                        size: 18,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(
                                    DesignSystem.Colors.textPrimary
                                )
                                .matchedGeometryEffect(
                                    id: "TitleText",
                                    in: animationNamespace
                                )
                        }
                        .onTapGesture {
                            HapticManager.shared.playSelection()
                            withAnimation(
                                .spring(response: 0.3, dampingFraction: 0.7)
                            ) {
                                isSearchExpanded = true
                            }
                        }
                    }
                }
                .frame(height: 50)
                .frame(maxWidth: isSearchExpanded ? .infinity : 160)
                .padding(.horizontal, isSearchExpanded ? 16 : 0)
            }
            .frame(height: 60)
            
            // KATEGORİLER (Sadece Arama Açıkken)
            if isSearchExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryPill(
                            type: nil,
                            isSelected: viewModel.selectedType == nil,
                            action: {
                                withAnimation { viewModel.selectedType = nil }
                            }
                        )
                        
                        ForEach(NoteType.allCases, id: \.self) { type in
                            CategoryPill(
                                type: type,
                                isSelected: viewModel.selectedType == type,
                                action: {
                                    withAnimation {
                                        viewModel.selectedType = type
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 5)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // ... (Diğer tüm alt görünümler aynı kalıyor: emptyStateView, noResultsView, floatingRecordingBar, Helper Components)
    // Lütfen dosyanın geri kalanını silme, olduğu gibi koru.
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
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
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: AppConstants.Icons.magnifyingGlass)
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(AppConstants.Texts.Home.noResults)
                .font(DesignSystem.Typography.body())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                HapticManager.shared.playImpact(style: .heavy)
                withAnimation(
                    .spring(
                        response: AppConstants.Animation.springResponse,
                        dampingFraction: AppConstants.Animation.springDamping
                    )
                ) {
                    if viewModel.audioManager.isRecording {
                        viewModel.audioManager.stopRecording()
                        HapticManager.shared.playNotification(type: .success)
                    } else {
                        viewModel.audioManager.startRecording()
                    }
                }
            } label: {
                ZStack {
                    if viewModel.audioManager.isRecording { PulsingBlob() }
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: DesignSystem.Effects.shadowMedium,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    if viewModel.isAnalyzing { ProgressView().tint(DesignSystem.Colors.primaryPurple) } else {
                        Image(
                            systemName: viewModel.audioManager.isRecording ? AppConstants.Icons.stopFill : AppConstants.Icons.micFill
                        )
                        .font(.title2)
                        .foregroundStyle(
                            viewModel.audioManager.isRecording ? DesignSystem.Gradients.recordingAction : DesignSystem.Gradients.primaryAction
                        )
                    }
                }
            }.disabled(viewModel.isAnalyzing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 40)
        .padding(.horizontal)
        .scaleEffect(viewModel.audioManager.isRecording ? 1.02 : 1.0)
    }
}

// MARK: - YARDIMCI BİLEŞENLER

struct CategoryPill: View {
    let type: NoteType?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let type = type {
                    Image(systemName: type.iconName).font(.caption)
                } else {
                    Image(systemName: "square.grid.2x2.fill").font(.caption)
                }
                Text(type?.rawValue ?? "Tümü")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background {
                if isSelected {
                    if let type = type { Color(hex: type.colorHex) } else {
                        DesignSystem.Colors.primaryBlue
                    }
                } else {
                    ZStack { Rectangle().fill(.ultraThinMaterial); Color.white.opacity(0.1) }
                }
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? .clear : Color.primary.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .foregroundStyle(isSelected ? .white : .primary.opacity(0.8))
            .shadow(
                color: isSelected ? (
                    type != nil ? Color(
                        hex: type!.colorHex
                    ) : DesignSystem.Colors.primaryBlue
                )
                .opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
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
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false)
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
    
    @State private var mapScale: CGFloat = 0.6
    @State private var mapOffset: CGSize = .zero
    @State private var currentDragOffset: CGSize = .zero
    @State private var currentMagnification: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                    .ignoresSafeArea()
                
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
                                        let newScale = mapScale * val
                                        mapScale = min(max(newScale, 0.2), 3.0)
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
                        mapControls.padding(.trailing, 20).padding(.bottom, 50)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
                    mapScale = 0.6; mapOffset = .zero
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
                action: { withAnimation { mapScale = max(mapScale - 0.5, 0.2) }
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

