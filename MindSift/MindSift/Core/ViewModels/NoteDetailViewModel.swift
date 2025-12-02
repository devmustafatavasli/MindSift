//
//  NoteDetailViewModel.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//


import SwiftUI
import AVFoundation
import Combine

@MainActor
class NoteDetailViewModel: ObservableObject {
    let note: VoiceNote
    
    // Yöneticiler
    @Published var playerManager = AudioPlayerManager()
    
    // UI Durumları
    @Published var showShareSheet = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    init(note: VoiceNote) {
        self.note = note
    }
    
    func onAppear() {
        playerManager.setupPlayer(audioFileName: note.audioFileName)
    }
    
    func onDisappear() {
        if playerManager.isPlaying {
            playerManager.playPause()
        }
    }
    
    // 🎨 Helper: Akıllı Renk
    var accentColor: Color {
        if let hex = note.smartColor { return Color(hex: hex) }
        return DesignSystem.Colors.primaryBlue
    }
    
    // 🎙️ Helper: Akıllı İkon
    var iconName: String {
        note.smartIcon ?? note.type.iconName
    }
    
    // 📧 Mail Mantığı
    func openMailApp() {
        guard let subject = note.emailSubject, let body = note.emailBody else { return }
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:?subject=\(encodedSubject)&body=\(encodedBody)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                UIPasteboard.general.string = "Konu: \(subject)\n\n\(body)"
                alertMessage = AppConstants.Texts.Errors.mailAppNotFound
                showAlert = true
            }
        }
    }
    
    // 📤 Paylaşım Metni
    func generateShareText() -> String {
        """
        📄 \(note.title ?? "Sesli Not")
        
        ✨ \(AppConstants.Texts.Detail.aiSummaryTitle): \(note.summary ?? "")
        
        📝 \(AppConstants.Texts.Detail.transcriptTitle):
        \(note.transcription ?? "")
        \(AppConstants.Texts.Detail.shareSuffix)
        """
    }
}
