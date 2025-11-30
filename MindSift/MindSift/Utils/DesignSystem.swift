//
//  DesignSystem.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//

// MARK: MindSift Design System
// Renkleri, fontları ve efektleri tek bir DesignSystem üzerinden yöneteceğiz.

import SwiftUI

struct DesignSystem {
    
    struct Colors {
        // Ana Renkler (with Hex Codes)
        static let primaryPurple = Color(hex: "6A11CB")
        static let primaryBlue = Color(hex: "2575FC")
        static let accentPink = Color(hex: "FF416C")
        static let accentOrange = Color(hex: "FF4B2B")
        // Metin Renkleri
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary.opacity(0.8)
        // Arkaplan için özel siyah-beyaz tonlar
        static let glassBorder = Color.white.opacity(0.4)
        static let glassSurface = Color.white.opacity(0.1)
    }
    
    struct Gradients {
        // Mesh Gradient simülasyonu için kullanılacak renkler
        static let meshColors: [Color] = [
            Colors.primaryBlue.opacity(0.4),
            Colors.primaryPurple.opacity(0.3),
            Colors.accentPink.opacity(0.2),
            Color.cyan.opacity(0.3)
        ]
        // Kartların NoteType özelinde tintleri
        static func cardGradient(for type: NoteType) -> LinearGradient {
            let colors: [Color]
            switch type {
            case .meeting: colors = [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]
            case .email:   colors = [Color.purple.opacity(0.15), Color.purple.opacity(0.05)]
            case .task:    colors = [Color.orange.opacity(0.15), Color.orange.opacity(0.05)]
            case .travel:  colors = [Color.cyan.opacity(0.15), Color.green.opacity(0.05)]
            default:       colors = [Color.gray.opacity(0.15), Color.gray.opacity(0.05)]
            }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        static let primaryAction = LinearGradient(
            colors: [Colors.primaryPurple, Colors.primaryBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let recordingAction = LinearGradient(
            colors: [Colors.accentPink, Colors.accentOrange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    struct Typography {
        static func titleLarge() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
        static func headline() -> Font { .system(.headline, design: .rounded) }
        static func subheadline() -> Font { .system(.subheadline, design: .rounded) }
        static func body() -> Font { .system(.body, design: .rounded) }
        static func caption() -> Font { .system(.caption, design: .rounded) }
    }
    
    struct Effects {
        static let shadowLight = Color.black.opacity(0.1)
        static let shadowMedium = Color.black.opacity(0.2)
    }
}

// MARK: View Modifiers
// "Liquid Glass" Efekti ile Cam Hissiyatı
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            // ultraThinMaterial ile buzlu cam hissiyatı verdik.
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: DesignSystem.Effects.shadowLight, radius: 15, x: 0, y: 10)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
    
    func mainBackground() -> some View {
        self.background(Color(uiColor: .systemGroupedBackground))
    }
}

// Gemini: Hex Renk Desteği (Detayını Anla.)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}
