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
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: VoiceNote.self)
    }
}
