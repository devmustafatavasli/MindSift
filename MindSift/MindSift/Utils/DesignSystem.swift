//
//  DesignSystem.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//

import SwiftUI

struct DesignSystem {

    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(uiColor: .systemBackground),
            Color.blue.opacity(0.05),
            Color.purple.opacity(0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let recordingGradient = LinearGradient(
        colors: [Color.red, Color.orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// View Extension ile Daha Kolay Kullanım
extension View {
    
    func mainBackground() -> some View {
        self.background(DesignSystem.backgroundGradient.ignoresSafeArea())
    }
    
    func glassCard() -> some View {
        self.background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
