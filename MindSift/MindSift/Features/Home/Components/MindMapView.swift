//
//  MindMapView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 1.12.2025.
//

import SwiftUI

struct MindMapView: View {
    let notes: [VoiceNote]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Her not için bir "Düğüm" (Node) oluşturuyoruz
                ForEach(
                    Array(notes.enumerated()),
                    id: \.element.id
                ) {
 index,
 note in
                    MindMapNode(note: note)
                        .position(
                            x: generatePosition(
                                for: index,
                                in: geometry.size
                            ).x,
                            y: generatePosition(for: index, in: geometry.size).y
                        )
                }
            }
        }
    }
    
    // Basit bir dağılım algoritması (Spiral veya Rastgele)
    // MVP için rastgele ama merkezden dağılan bir yapı kuruyoruz
    private func generatePosition(for index: Int, in size: CGSize) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Basit Spiral Mantığı
        let angle = Double(index) * 0.8 // Her notta açıyı değiştir
        let radius = Double(index * 30) + 50 // Her notta merkezden uzaklaş
        
        let x = centerX + CGFloat(cos(angle) * radius)
        let y = centerY + CGFloat(sin(angle) * radius)
        
        // Ekran dışına taşmayı engelle (Basit clamp)
        let clampedX = min(max(x, 40), size.width - 40)
        let clampedY = min(
            max(y, 100),
            size.height - 200
        ) // Üst ve alt boşluklar
        
        return CGPoint(x: clampedX, y: clampedY)
    }
}

// TEKİL DÜĞÜM TASARIMI
struct MindMapNode: View {
    let note: VoiceNote
    @State private var isDragging = false
    @State private var offset = CGSize.zero
    
    // Akıllı Renk
    var accentColor: Color {
        if let hex = note.smartColor { return Color(hex: hex) }
        return .blue
    }
    
    var iconName: String { note.smartIcon ?? note.type.iconName }
    
    var body: some View {
        NavigationLink(destination: NoteDetailView(note: note)) {
            VStack(spacing: 8) {
                // İkon Dairesi
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.6), lineWidth: 2)
                        )
                        .shadow(color: accentColor.opacity(0.3), radius: 10)
                    
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(accentColor)
                }
                
                // Başlık (Küçük)
                Text(note.title ?? "Not")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .frame(maxWidth: 100)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .offset(offset)
        // Sürükleme Özelliği (Drag Gesture)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring()) {
                        offset = value.translation
                    }
                }
                .onEnded { _ in
                    // İstersen burada yeni konumu kaydedebilirsin (Şimdilik geri dönüyor)
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                }
        )
    }
}
