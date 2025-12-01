//
//  MindSiftApp.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 23.11.2025.
//

import SwiftUI
import SwiftData

@main
struct MindSiftApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    // 👇 YENİ: Ortak Veritabanı Konteyneri
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VoiceNote.self,
        ])
        
        // App Group Kimliği (Xcode'da oluşturduğunla AYNI olmalı)
        // Örn: "group.com.baris.MindSift"
        let appGroupIdentifier = "group.com.devmustafatavasli.MindSift"
        
        let modelConfiguration: ModelConfiguration
        
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            let storeURL = containerURL.appendingPathComponent(
                "MindSift.sqlite"
            )
            modelConfiguration = ModelConfiguration(
                url: storeURL,
                allowsSave: true
            )
        } else {
            // Hata durumunda varsayılan (fallback)
            print("⚠️ App Group bulunamadı, varsayılan depolama kullanılıyor.")
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        // Oluşturduğumuz ortak konteyneri kullan
        .modelContainer(sharedModelContainer)
    }
}
