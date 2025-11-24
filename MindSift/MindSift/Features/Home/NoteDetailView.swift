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
    
    var body: some View {
        ZStack {
            // Arka Plan
            DesignSystem.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. BAŞLIK VE TARİH ALANI
                    VStack(alignment: .leading, spacing: 8) {
                        Text(note.title ?? "İsimsiz Not")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(
                                note.createdAt
                                    .formatted(date: .long, time: .shortened)
                            )
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 2. AI ÖZET KARTI (Varsa)
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
                    
                    // 3. TAKVİM BİLGİSİ (Varsa)
                    if let eventDate = note.eventDate {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("Etkinlik Zamanı")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(
                                    eventDate
                                        .formatted(
                                            date: .complete,
                                            time: .shortened
                                        )
                                )
                                .font(.headline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 4. TAM METİN (Transkript)
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Not İçeriği", systemImage: "text.alignleft")
                            .font(.headline)
                            .foregroundStyle(.gray)
                        
                        Text(note.transcription ?? "Ses çözülemedi.")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(6) // Okumayı kolaylaştırır
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
        // Navigasyon Bar Ayarları
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
        // Paylaşım Sayfası (Sheet)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    // Paylaşılacak metni oluştur
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

// Paylaşım Menüsü İçin Yardımcı Yapı (UIKit Wrapper)
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
