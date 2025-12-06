//
//  MindMapView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 1.12.2025.
//

import SwiftUI
import Accelerate

struct MindMapView: View {
    let notes: [VoiceNote]
    
    @State private var positions: [UUID: CGPoint] = [:]
    // 👇 YENİ: Seçili notu tutarak navigasyonu tetikleyeceğiz
    @State private var selectedNote: VoiceNote?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Bağlantı Çizgileri
                connectionsView
                
                // Düğümler
                ForEach(notes) { note in
                    if let position = positions[note.id] {
                        MindMapNode(note: note)
                            .position(position)
                            .animation(
                                .interactiveSpring(
                                    response: 0.5,
                                    dampingFraction: 0.7
                                ),
                                value: position
                            )
                        // 👇 DÜZELTME 2: Tap Gesture ile kesin algılama
                            .onTapGesture {
                                print("Tıklandı: \(note.title ?? "")")
                                selectedNote = note
                            }
                    }
                }
            }
            .onAppear { startSimulation(in: geometry.size) }
            .onChange(of: notes) { _, _ in startSimulation(in: geometry.size) }
            // 👇 DÜZELTME 3: Programatik Navigasyon
            .navigationDestination(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
        }
    }
    
    // ... (connectionsView AYNI KALACAK) ...
    private var connectionsView: some View {
        Path { path in
            guard notes.count > 1 else { return }
            for i in 0..<notes.count {
                for j in (i+1)..<notes.count {
                    let noteA = notes[i]
                    let noteB = notes[j]
                    guard let posA = positions[noteA.id], let posB = positions[noteB.id] else {
                        continue
                    }
                    
                    if let vecA = noteA.embedding, let vecB = noteB.embedding {
                        let similarity = calculateCosineSimilarity(vecA, vecB)
                        
#if targetEnvironment(simulator)
                        let threshold: Float = 0.1
#else
                        let threshold: Float = 0.75
#endif
                        
                        if similarity > threshold {
                            path.move(to: posA)
                            path.addLine(to: posB)
                        }
                    }
                }
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
    
    // MARK: - Force-Directed Simulation Logic
    
    private func startSimulation(in size: CGSize) {
        guard !notes.isEmpty else { return }
        
        var currentPositions: [UUID: CGPoint] = [:]
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for note in notes {
            if let existing = positions[note.id] {
                currentPositions[note.id] = existing
            } else {
                let randomX = CGFloat.random(in: -50...50) + center.x
                let randomY = CGFloat.random(in: -50...50) + center.y
                currentPositions[note.id] = CGPoint(x: randomX, y: randomY)
            }
        }
        self.positions = currentPositions
        
        Task {
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 15_000_000)
                await MainActor.run {
                    self.positions = runForceIteration(
                        currentPositions: self.positions,
                        size: size
                    )
                }
            }
        }
    }
    
    private func runForceIteration(currentPositions: [UUID: CGPoint], size: CGSize) -> [UUID: CGPoint] {
        var newPositions = currentPositions
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // 👇 DÜZELTME 4: Fizik Parametrelerini Güncelledik (Daha geniş alan)
        let repulsionForce: CGFloat = 8000.0 // 5000 -> 8000 (Daha fazla itme)
        let springLength: CGFloat = 150.0    // 120 -> 150 (Daha uzun bağlar)
        let attractionFactor: CGFloat = 0.8
        let centerGravity: CGFloat = 0.05    // 0.08 -> 0.05 (Merkeze daha az yapışsınlar)
        
        var velocities: [UUID: CGPoint] = [:]
        for note in notes { velocities[note.id] = .zero }
        
        // A. İtme
        for i in 0..<notes.count {
            let nodeA = notes[i]
            guard let posA = currentPositions[nodeA.id] else { continue }
            
            for j in (i+1)..<notes.count {
                let nodeB = notes[j]
                guard let posB = currentPositions[nodeB.id] else { continue }
                
                let dx = posA.x - posB.x
                let dy = posA.y - posB.y
                let distance = sqrt(dx*dx + dy*dy) + 0.1
                
                let force = repulsionForce / (distance * distance)
                let fx = (dx / distance) * force
                let fy = (dy / distance) * force
                
                velocities[nodeA.id]!.x += fx
                velocities[nodeA.id]!.y += fy
                velocities[nodeB.id]!.x -= fx
                velocities[nodeB.id]!.y -= fy
            }
        }
        
        // B. Çekim
        for i in 0..<notes.count {
            let nodeA = notes[i]
            guard let posA = currentPositions[nodeA.id] else { continue }
            
            for j in (i+1)..<notes.count {
                let nodeB = notes[j]
                guard let posB = currentPositions[nodeB.id] else { continue }
                
                var similarity: Float = 0.0
                if let vecA = nodeA.embedding, let vecB = nodeB.embedding {
                    similarity = calculateCosineSimilarity(vecA, vecB)
                }
                
#if targetEnvironment(simulator)
                let threshold: Float = 0.0
#else
                let threshold: Float = 0.6
#endif
                
                if similarity > threshold {
                    let dx = posA.x - posB.x
                    let dy = posA.y - posB.y
                    let distance = sqrt(dx*dx + dy*dy) + 0.1
                    
                    let targetDistance = springLength * CGFloat(
                        1.0 - similarity
                    )
                    let displacement = distance - targetDistance
                    let force = displacement * attractionFactor * CGFloat(
                        similarity
                    )
                    
                    let fx = (dx / distance) * force
                    let fy = (dy / distance) * force
                    
                    velocities[nodeA.id]!.x -= fx
                    velocities[nodeA.id]!.y -= fy
                    velocities[nodeB.id]!.x += fx
                    velocities[nodeB.id]!.y += fy
                }
            }
        }
        
        // C. Yerçekimi & D. Güncelleme
        for note in notes {
            guard let pos = currentPositions[note.id] else { continue }
            let dx = center.x - pos.x
            let dy = center.y - pos.y
            
            velocities[note.id]!.x += dx * centerGravity
            velocities[note.id]!.y += dy * centerGravity
            
            guard let velocity = velocities[note.id] else { continue }
            
            var newX = pos.x + velocity.x
            var newY = pos.y + velocity.y
            
            newX = max(50, min(size.width - 50, newX))
            newY = max(100, min(size.height - 100, newY))
            
            newPositions[note.id] = CGPoint(x: newX, y: newY)
        }
        
        return newPositions
    }
    
    // ... (calculateCosineSimilarity AYNI KALACAK) ...
    private func calculateCosineSimilarity(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else { return 0.0 }
        let count = vDSP_Length(vectorA.count)
        var dotProduct: Float = 0.0
        vDSP_dotpr(vectorA, 1, vectorB, 1, &dotProduct, count)
        var normA: Float = 0.0
        vDSP_svesq(vectorA, 1, &normA, count)
        normA = sqrt(normA)
        var normB: Float = 0.0
        vDSP_svesq(vectorB, 1, &normB, count)
        normB = sqrt(normB)
        if normA == 0 || normB == 0 { return 0.0 }
        return dotProduct / (normA * normB)
    }
}

// 👇 DÜZELTME 5: NavigationLink kaldırıldı, sadece görsel
struct MindMapNode: View {
    let note: VoiceNote
    
    var accentColor: Color {
        if let hex = note.smartColor { return Color(hex: hex) }
        return .blue
    }
    
    var iconName: String { note.smartIcon ?? note.type.iconName }
    
    var body: some View {
        // NavigationLink YOK, tıklama MindMapView içinde onTapGesture ile yönetiliyor
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(accentColor.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: accentColor.opacity(0.3), radius: 10)
                
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(accentColor)
            }
            
            Text(note.title ?? "Not")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .frame(maxWidth: 120)
                .lineLimit(1)
        }
        .contentShape(Rectangle()) // Tıklama alanını garantile
    }
}
