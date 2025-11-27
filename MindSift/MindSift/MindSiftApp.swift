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
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: VoiceNote.self)
    }
}
