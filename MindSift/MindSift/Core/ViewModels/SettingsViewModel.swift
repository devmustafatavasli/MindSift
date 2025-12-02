//
//  SettingsViewModel.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // Auth Manager'a erişim
    let authManager = AuthenticationManager()
    
    // UI Durumları
    @Published var showDeleteAlert = false
    
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
