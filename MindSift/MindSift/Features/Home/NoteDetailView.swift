//
//  NoteDetailView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//

import SwiftUI

struct NoteDetailView: View {
    // 1. DEĞİŞİKLİK: @StateObject yerine @State
    // iOS 17+ Observation framework'ü ile class'ları @State içinde tutabiliriz.
    @State private var viewModel: NoteDetailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    // Dependency Injection
    init(note: VoiceNote) {
        // 2. DEĞİŞİKLİK: StateObject yerine State(initialValue:)
        _viewModel = State(initialValue: NoteDetailViewModel(note: note))
    }
    
    var body: some View {
        // 3. DEĞİŞİKLİK: Binding işlemi için @Bindable
        // Bu satır sayesinde $viewModel.showShareSheet gibi bağlamaları yapabiliriz.
        @Bindable var viewModel = viewModel
        
        ZStack {
            DesignSystem.Gradients.primaryAction
                .opacity(0.05)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. BAŞLIK
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.accentColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: viewModel.iconName)
                                    .foregroundStyle(viewModel.accentColor)
                                    .font(.title2)
                            }
                            
                            Text(viewModel.note.type.rawValue)
                                .font(DesignSystem.Typography.caption())
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.accentColor.opacity(0.1))
                                .foregroundStyle(viewModel.accentColor)
                                .clipShape(Capsule())
                        }
                        
                        Text(viewModel.note.title ?? "İsimsiz Not")
                            .font(DesignSystem.Typography.titleLarge())
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        
                        Text(
                            viewModel.note.createdAt
                                .formatted(date: .long, time: .shortened)
                        )
                        .font(DesignSystem.Typography.subheadline())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // 2. SES OYNATICI
                    VStack(spacing: 12) {
                        HStack {
                            Button {
                                viewModel.playerManager.playPause()
                            } label: {
                                Image(
                                    systemName: viewModel.playerManager.isPlaying ? AppConstants.Icons.pause : AppConstants.Icons.play
                                )
                                .font(.system(size: 44))
                                .foregroundStyle(viewModel.accentColor)
                                .background(Circle().fill(.white).padding(4))
                                .shadow(radius: 2)
                            }
                            
                            VStack(spacing: 4) {
                                Slider(
                                    value: Binding(
                                        get: {
                                            viewModel.playerManager.currentTime
                                        },
                                        set: {
                                            viewModel.playerManager.seek(to: $0)
                                        }
                                    ),
                                    in: 0...viewModel.playerManager.duration
                                )
                                .tint(viewModel.accentColor)
                                
                                HStack {
                                    Text(
                                        formatTime(
                                            viewModel.playerManager.currentTime
                                        )
                                    )
                                    Spacer()
                                    Text(
                                        formatTime(
                                            viewModel.playerManager.duration
                                        )
                                    )
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                viewModel.accentColor.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    
                    // 3. MAİL AKSİYON KARTI
                    if viewModel.note.type == .email, let subject = viewModel.note.emailSubject, let body = viewModel.note.emailBody {
                        VStack(alignment: .leading, spacing: 16) {
                            Label(
                                AppConstants.Texts.Detail.emailDraftTitle,
                                systemImage: AppConstants.Icons.envelope
                            )
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("KONU")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(subject)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                Divider().overlay(.white.opacity(0.3))
                                Text("İÇERİK")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(body)
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .lineLimit(4)
                            }
                            
                            Button { viewModel.openMailApp() } label: {
                                HStack {
                                    Text(
                                        AppConstants.Texts.Detail.openMailButton
                                    )
                                    Spacer()
                                    Image(
                                        systemName: AppConstants.Icons.arrowUpRight
                                    )
                                }
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.white)
                                .foregroundStyle(viewModel.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    viewModel.accentColor,
                                    viewModel.accentColor.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(
                            color: viewModel.accentColor.opacity(0.3),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    }
                    
                    // 4. AI ÖZET
                    if let summary = viewModel.note.summary {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(
                                AppConstants.Texts.Detail.aiSummaryTitle,
                                systemImage: AppConstants.Icons.sparkles
                            )
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(viewModel.accentColor)
                            Text(summary)
                                .font(DesignSystem.Typography.body())
                                .foregroundStyle(
                                    DesignSystem.Colors.textPrimary.opacity(0.9)
                                )
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.accentColor.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    }
                    
                    // 5. TRANSKRİPT
                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            AppConstants.Texts.Detail.transcriptTitle,
                            systemImage: AppConstants.Icons.textAlignLeft
                        )
                        .font(DesignSystem.Typography.headline())
                        .foregroundStyle(.gray)
                        Text(
                            viewModel.note.transcription ?? AppConstants.Texts.Detail.audioError
                        )
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineSpacing(6)
                    }
                    .padding()
                    .background(
                        Color(uiColor: .secondarySystemBackground).opacity(0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.showShareSheet = true } label: {
                    Image(systemName: AppConstants.Icons.share)
                        .foregroundStyle(viewModel.accentColor)
                }
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: [viewModel.generateShareText()])
        }
        .alert(
            AppConstants.Texts.Actions.ok,
            isPresented: $viewModel.showAlert
        ) {
            Button(AppConstants.Texts.Actions.ok, role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
