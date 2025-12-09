//
//  HapticManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 8.12.2025.
//


//
//  HapticManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 8.12.2025.
//

import UIKit

class HapticManager {
    // Singleton: Her yerden tek erişim
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Bildirim Titreşimleri (Başarı, Hata vb.)
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Vuruş Titreşimleri (Buton tıklama, çarpışma)
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Seçim Titreşimi (Picker, Scroll)
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}