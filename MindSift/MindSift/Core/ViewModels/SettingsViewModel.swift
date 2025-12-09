//
//  SettingsViewModel.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import Foundation
import SwiftData
import SwiftUI
import Observation // 👈 YENİ

@MainActor
@Observable // 👈 ARTIK BU VAR
class SettingsViewModel {
    // Auth Manager'a erişim (Değişiklikler otomatik izlenir)
    var authManager = AuthenticationManager()
    
    // UI Durumları
    var showDeleteAlert = false
    
    // Verileri Silme Mantığı
    func deleteAllData(context: ModelContext) {
        do {
            try context.delete(model: VoiceNote.self)
            print("🗑️ Tüm veriler temizlendi.")
        } catch {
            print("Silme hatası: \(error)")
        }
    }
}
