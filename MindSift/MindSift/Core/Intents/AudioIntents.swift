//
//  StopRecordingIntent.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 8.12.2025.
//

import AppIntents
import Foundation

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Kaydı Durdur"
    
    // Intent tetiklendiğinde çalışacak kod
    func perform() async throws -> some IntentResult {
        // AudioManager'ın paylaşılan örneğine ulaşıp durduruyoruz
        // NOT: AudioManager.swift içine 'static let shared = AudioManager()' eklediğinden emin ol.
        // Eğer singleton kullanmıyorsan, NotificationCenter ile de haberleşebilirsin.
        await MainActor.run {
            // Basitlik adına Notification gönderiyoruz, AudioManager bunu dinleyebilir
            NotificationCenter.default
                .post(
                    name: NSNotification.Name("StopRecordingFromIsland"),
                    object: nil
                )
        }
        return .result()
    }
}
