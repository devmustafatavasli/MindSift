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
    @State private var selectedNote: VoiceNote?
    
    // 👇 GÜNCELLEME: Yörünge yarıçapını küçülttük (0.35 -> 0.22)
    // Böylece kategoriler ekranın dışına taşmak yerine merkeze toplanacak.
    private func getCategoryCenter(type: NoteType, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.22
        
        let allTypes = NoteType.allCases
        guard let index = allTypes.firstIndex(of: type) else { return center }
        
        let angleStep = (2 * CGFloat.pi) / CGFloat(allTypes.count)
        let angle = angleStep * CGFloat(index) - (CGFloat.pi / 2)
        
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !notes.isEmpty {
                    categoryLabelsView(in: geometry.size)
                }
                
                connectionsView
                
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
                            .onTapGesture {
                                selectedNote = note
                            }
                    }
                }
            }
            .onAppear { startSimulation(in: geometry.size) }
            .onChange(of: notes) { _, _ in startSimulation(in: geometry.size) }
            .navigationDestination(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
        }
    }
    
    // MARK: - Views
    
    private func categoryLabelsView(in size: CGSize) -> some View {
        ForEach(NoteType.allCases, id: \.self) { type in
            if notes.contains(where: { $0.type == type }) {
                let center = getCategoryCenter(type: type, in: size)
                Text(type.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .position(center)
            }
        }
    }
    
    private var connectionsView: some View {
        Path { path in
            guard notes.count > 1 else { return }
            for i in 0..<notes.count {
                for j in (i+1)..<notes.count {
                    let noteA = notes[i]
                    let noteB = notes[j]
                    
                    guard let posA = positions[noteA.id],
                          let posB = positions[noteB.id],
                          let vecA = noteA.embedding,
                          let vecB = noteB.embedding else { continue }
                    
                    let similarity = calculateCosineSimilarity(vecA, vecB)
                    
#if targetEnvironment(simulator)
                    let threshold: Float = 0.6
#else
                    let threshold: Float = 0.70
#endif
                    
                    if similarity > threshold {
                        path.move(to: posA)
                        path.addLine(to: posB)
                    }
                }
            }
        }
        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
    }
    
    // MARK: - Force-Directed Simulation Logic
    
    private func startSimulation(in size: CGSize) {
        guard !notes.isEmpty else { return }
        
        var currentPositions: [UUID: CGPoint] = [:]
        
        for note in notes {
            if let existing = positions[note.id] {
                currentPositions[note.id] = existing
            } else {
                let targetCenter = getCategoryCenter(type: note.type, in: size)
                let randomX = CGFloat.random(in: -20...20) + targetCenter.x
                let randomY = CGFloat.random(in: -20...20) + targetCenter.y
                currentPositions[note.id] = CGPoint(x: randomX, y: randomY)
            }
        }
        self.positions = currentPositions
        
        Task {
            for _ in 0..<120 {
                try? await Task.sleep(nanoseconds: 10_000_000)
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
        var velocities: [UUID: CGPoint] = [:]
        for note in notes { velocities[note.id] = .zero }
        
        // 👇 GÜNCELLEME: Fizik Kuralları (Daha kompakt yapı)
        let repulsionForce: CGFloat = 3500.0 // (Eski: 6000) Daha az itme, daha sıkı duruş
        let springLength: CGFloat = 80.0     // (Eski: 150) Bağlı notlar birbirine daha yakın
        let attractionForce: CGFloat = 0.08
        let categoryGravity: CGFloat = 0.12  // (Eski: 0.08) Kategorisine daha sıkı tutunsun
        
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
                
                if distance > 300 { continue }
                
                let force = repulsionForce / (distance * distance)
                let fx = (dx / distance) * force
                let fy = (dy / distance) * force
                
                velocities[nodeA.id]!.x += fx
                velocities[nodeA.id]!.y += fy
                velocities[nodeB.id]!.x -= fx
                velocities[nodeB.id]!.y -= fy
            }
        }
        
        // B. Çekim (Bağlantılar)
        for i in 0..<notes.count {
            let nodeA = notes[i]
            guard let posA = currentPositions[nodeA.id] else { continue }
            
            for j in (i+1)..<notes.count {
                let nodeB = notes[j]
                guard let posB = currentPositions[nodeB.id] else { continue }
                
                if let vecA = nodeA.embedding, let vecB = nodeB.embedding {
                    let similarity = calculateCosineSimilarity(vecA, vecB)
                    
#if targetEnvironment(simulator)
                    let threshold: Float = 0.5
#else
                    let threshold: Float = 0.7
#endif
                    
                    if similarity > threshold {
                        let dx = posB.x - posA.x
                        let dy = posB.y - posA.y
                        let distance = sqrt(dx*dx + dy*dy) + 0.1
                        
                        let targetDistance = springLength * CGFloat(
                            1.0 - similarity
                        )
                        let displacement = distance - targetDistance
                        let force = displacement * attractionForce * CGFloat(
                            similarity
                        )
                        
                        let fx = (dx / distance) * force
                        let fy = (dy / distance) * force
                        
                        velocities[nodeA.id]!.x += fx
                        velocities[nodeA.id]!.y += fy
                        velocities[nodeB.id]!.x -= fx
                        velocities[nodeB.id]!.y -= fy
                    }
                }
            }
        }
        
        // C. Kategori Yerçekimi
        for note in notes {
            guard let pos = currentPositions[note.id] else { continue }
            let target = getCategoryCenter(type: note.type, in: size)
            
            let dx = target.x - pos.x
            let dy = target.y - pos.y
            
            velocities[note.id]!.x += dx * categoryGravity
            velocities[note.id]!.y += dy * categoryGravity
            
            guard let v = velocities[note.id] else { continue }
            
            var newX = pos.x + v.x
            var newY = pos.y + v.y
            
            let padding: CGFloat = 60
            newX = max(padding, min(size.width - padding, newX))
            newY = max(padding, min(size.height - padding, newY))
            
            newPositions[note.id] = CGPoint(x: newX, y: newY)
        }
        
        return newPositions
    }
    
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

// MARK: - Node View
struct MindMapNode: View {
    let note: VoiceNote
    var accentColor: Color {
        if let hex = note.smartColor { return Color(hex: hex) }
        return .blue
    }
    var iconName: String { note.smartIcon ?? note.type.iconName }
    
    var body: some View {
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
        .contentShape(Rectangle())
    }
}
