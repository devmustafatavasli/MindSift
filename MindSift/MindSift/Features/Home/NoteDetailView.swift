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
    
    // 👇 YENİ: Hata mesajı için durumlar
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Arka Plan
            DesignSystem.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. BAŞLIK ALANI
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: note.type.iconName)
                                .foregroundStyle(.blue)
                                .font(.title2)
                            
                            Text(note.type.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
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
                    
                    // 2. MAİL AKSİYON KARTI
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
                            
                            Button {
                                openMailApp(subject: subject, body: body)
                            } label: {
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
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(
                            color: .blue.opacity(0.3),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    }
                    
                    // 3. AI ÖZET KARTI
                    if let summary = note.summary {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("AI Özeti", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(.purple)
                            
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
                                .stroke(.purple.opacity(0.1), lineWidth: 1)
                        )
                    }
                    
                    // 4. TAM METİN
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
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
        // 👇 YENİ: Hata Alert'i
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // 👇 GÜNCELLENMİŞ FONKSİYON: Hata Yönetimi Ekli
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
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Mail uygulaması yoksa (Simülatör durumu)
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
