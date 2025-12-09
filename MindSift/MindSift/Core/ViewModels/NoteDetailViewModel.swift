//
//  NoteDetailViewModel.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import SwiftUI
import AVFoundation
import Observation // 👈 YENİ: iOS 17+ Modern İzleme Framework'ü

@MainActor
@Observable // 👈 ARTIK BU VAR (ObservableObject yerine)
class NoteDetailViewModel {
    
    let note: VoiceNote
    
    // Yöneticiler
    // @Published YOK. AudioPlayerManager da @Observable olduğu için,
    // SwiftUI içindeki değişiklikleri (süre, oynatma durumu) otomatik algılar.
    var playerManager = AudioPlayerManager()
    
    // UI Durumları
    // Düz değişkenler artık otomatik izleniyor.
    var showShareSheet = false
    var showAlert = false
    var alertMessage = ""
    
    init(note: VoiceNote) {
        self.note = note
    }
    
    func onAppear() {
        // Audio dosya isminden kurulumu başlat
        playerManager.setupPlayer(audioFileName: note.audioFileName)
    }
    
    func onDisappear() {
        // Sayfadan çıkınca çalıyorsa durdur
        if playerManager.isPlaying {
            playerManager
                .stop() // playPause yerine stop() daha temiz bir temizlik yapar
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
        guard let subject = note.emailSubject, let body = note.emailBody else {
            return
        }
        
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
