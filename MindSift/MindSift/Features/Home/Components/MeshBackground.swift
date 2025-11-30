//
//  MeshBackground.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 28.11.2025.
//


import SwiftUI

struct MeshBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Taban Rengi
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // Hareketli Blob 1 (Mavi/Mor)
            Circle()
                .fill(DesignSystem.Colors.primaryPurple.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? -100 : 100)
                .animation(
                    .easeInOut(duration: 10).repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Hareketli Blob 2 (Mavi/Camgöbeği)
            Circle()
                .fill(DesignSystem.Colors.primaryBlue.opacity(0.4))
                .frame(width: 350, height: 350)
                .blur(radius: 60)
                .offset(x: animate ? 150 : -150, y: animate ? 100 : -100)
                .animation(
                    .easeInOut(duration: 12).repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Hareketli Blob 3 (Accent)
            Circle()
                .fill(DesignSystem.Colors.accentPink.opacity(0.3))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: animate ? -50 : 50, y: animate ? 200 : -200)
                .animation(
                    .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Glass Yüzey (Blur katmanı) - Tüm renkleri birleştirip softlaştırır
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.6) // Arka planın ne kadar "flulaşacağını" ayarlar
                .ignoresSafeArea()
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    MeshBackground()
}
