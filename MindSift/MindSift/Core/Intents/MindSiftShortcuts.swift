//
//  StartRecordingIntent.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 1.12.2025.
//

import AppIntents
import SwiftUI

// 1. Kestirme Tanımı (Intent)
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Sesli Not Al"
    static var description = IntentDescription("MindSift uygulamasını açar ve hemen ses kaydına başlar.")
    static var openAppWhenRun: Bool = true // Uygulamayı ön plana getir
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Uygulamayı özel URL ile açıyoruz
        if let url = URL(string: "mindsift://record") {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

// 2. Kestirme Sağlayıcısı (Provider)
// Bu kısım, Kestirmeler uygulamasında otomatik olarak görünmesini sağlar
struct MindSiftShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "${applicationName} ile kaydet",
                "${applicationName} ile not al",
                "${applicationName} ile sesli not başlat"
            ],
            shortTitle: "Not Al",
            systemImageName: "mic.circle.fill"
        )
    }
}
