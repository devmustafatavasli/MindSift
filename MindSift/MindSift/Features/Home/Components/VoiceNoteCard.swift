//
//  VoiceNoteCard.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//


import SwiftUI

struct VoiceNoteCard: View {
    let note: VoiceNote
    
    var priorityColor: Color {
        switch note.priority {
        case "Yüksek": return .red
        case "Orta": return .orange
        case "Düşük": return .green
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Üst Kısım
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(priorityColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: note.type.iconName)
                        .foregroundStyle(priorityColor)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title ?? "İsimsiz Not")
                        .font(.system(.headline, design: .rounded)) // Modern Font
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(note.createdAt.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let priority = note.priority {
                    Text(priority)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor.opacity(0.1))
                        .foregroundStyle(priorityColor)
                        .clipShape(Capsule())
                }
            }
            
            // Özet
            if let summary = note.summary {
                Text(summary)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Etkinlik Tarihi (Varsa) - Alt Kısım
            if let eventDate = note.eventDate {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    
                    Text(eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .padding(.top, 4)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .glassCard() // ✨ Sihirli Dokunuş: Glassmorphism
    }
}
