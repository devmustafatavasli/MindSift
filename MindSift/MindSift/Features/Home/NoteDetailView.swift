//
//  NoteDetailView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//

import SwiftUI

struct NoteDetailView: View {
    let note: VoiceNote
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // 👇 YENİ: Ses Oynatıcı Yöneticisi
    @StateObject private var playerManager = AudioPlayerManager()
    
    // Akıllı Renk
    var accentColor: Color {
        if let hex = note.smartColor { return Color(hex: hex) }
        return .blue
    }
    
    // Akıllı İkon
    var iconName: String { note.smartIcon ?? note.type.iconName }
    
    var body: some View {
        ZStack {
            // Arka Plan (Hafif tema rengiyle)
            DesignSystem.Gradients.primaryAction
                .opacity(0.05)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. BAŞLIK ALANI
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: iconName)
                                    .foregroundStyle(accentColor)
                                    .font(.title2)
                            }
                            
                            Text(note.type.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(accentColor.opacity(0.1))
                                .foregroundStyle(accentColor)
                                .clipShape(Capsule())
                        }
                        
                        Text(note.title ?? "İsimsiz Not")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(
                            note.createdAt
                                .formatted(date: .long, time: .shortened)
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 👇 YENİ: SES OYNATICI KARTI
                    VStack(spacing: 12) {
                        HStack {
                            // Play/Pause Butonu
                            Button {
                                playerManager.playPause()
                            } label: {
                                Image(
                                    systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill"
                                )
                                .font(.system(size: 44))
                                .foregroundStyle(accentColor)
                                .background(
                                    Circle().fill(.white).padding(4)
                                ) // Arka plan temizliği
                                .shadow(radius: 2)
                            }
                            
                            VStack(spacing: 4) {
                                // Slider (İlerleme Çubuğu)
                                Slider(value: Binding(
                                    get: { playerManager.currentTime },
                                    set: { playerManager.seek(to: $0) }
                                ), in: 0...playerManager.duration)
                                .tint(accentColor)
                                
                                // Süreler (00:00 / 01:25)
                                HStack {
                                    Text(formatTime(playerManager.currentTime))
                                    Spacer()
                                    Text(formatTime(playerManager.duration))
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
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    )
                    
                    // 2. MAİL AKSİYON KARTI (Varsa)
                    if note.type == .email, let subject = note.emailSubject, let body = note.emailBody {
                        VStack(alignment: .leading, spacing: 16) {
                            Label(
                                "E-posta Taslağı",
                                systemImage: "envelope.fill"
                            )
                            .font(.headline)
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
                            
                            Button { openMailApp(subject: subject, body: body) } label: {
                                HStack {
                                    Text("Mail Uygulamasında Aç")
                                    Spacer()
                                    Image(
                                        systemName: "arrow.up.right.circle.fill"
                                    )
                                }
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.white)
                                .foregroundStyle(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(
                            color: accentColor.opacity(0.3),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    }
                    
                    // 3. AI ÖZET
                    if let summary = note.summary {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("AI Özeti", systemImage: "sparkles")
                                .font(.headline).foregroundStyle(accentColor)
                            Text(summary)
                                .font(.body)
                                .foregroundStyle(.primary.opacity(0.9))
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // 4. TRANSKRİPT
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Transkript", systemImage: "text.alignleft")
                            .font(.headline)
                            .foregroundStyle(.gray)
                        Text(note.transcription ?? "Ses çözülemedi.")
                            .font(.body)
                            .foregroundStyle(.primary)
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
                Button { showShareSheet = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(accentColor)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        // 👇 Sayfa açılınca player'ı hazırla
        .onAppear {
            playerManager.setupPlayer(audioFileName: note.audioFileName)
        }
        // 👇 Sayfadan çıkınca durdur
        .onDisappear {
            playerManager.playPause() // Çalıyorsa durdurur
        }
    }
    
    // Süre Formatlayıcı
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func openMailApp(subject: String, body: String) {
        let encodedSubject = subject.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""
        let encodedBody = body.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""
        if let url = URL(
            string: "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
        ) {
            if UIApplication.shared
                .canOpenURL(url) { UIApplication.shared.open(url) }
            else {
                UIPasteboard.general.string = "Konu: \(subject)\n\n\(body)"
                alertMessage = "Mail uygulaması bulunamadı. İçerik panoya kopyalandı."
                showAlert = true
            }
        }
    }
    
    private func generateShareText() -> String {
        """
        📄 \(note.title ?? "Sesli Not")
        ✨ Özet: \(note.summary ?? "")
        📝 İçerik:
        \(note.transcription ?? "")
        🤖 MindSift ile oluşturuldu.
        """
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }
    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
    }
}
