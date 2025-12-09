//
//  VoiceNoteCard.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import SwiftUI

struct VoiceNoteCard: View {
    @Bindable var note: VoiceNote
    
    private let cardRadius: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. ÜST KISIM
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(Color(hex: note.type.colorHex).opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: note.smartIcon ?? note.type.iconName)
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(Color(hex: note.type.colorHex))
                }
                
                Spacer()
                
                if note.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption).foregroundStyle(.red)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                if note.type == .task {
                    Button {
                        withAnimation(
                            .spring(response: 0.3, dampingFraction: 0.6)
                        ) {
                            note.isCompleted.toggle()
                        }
                    } label: {
                        Image(
                            systemName: note.isCompleted ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.title2)
                        .foregroundStyle(note.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 2. İÇERİK
            VStack(alignment: .leading, spacing: 6) {
                Text(note.title ?? "İsimsiz Not")
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(3) // Başlık biraz daha uzun olabilir
                    .strikethrough(note.isCompleted, color: .secondary)
                
                if let summary = note.summary, !summary.isEmpty {
                    Text(summary)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(10) // Pinterest etkisi için uzun metin
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // 3. ALT BİLGİ
            HStack {
                Text(note.createdAt.formatted(date: .numeric, time: .omitted))
                    .font(.caption2).foregroundStyle(.secondary)
                
                Spacer()
                
                if let priority = note.priority, priority == "Yüksek" {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2).foregroundStyle(.red.opacity(0.8))
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .background(Color(hex: note.type.colorHex).opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: note.type.colorHex).opacity(0.4),
                            Color(hex: note.type.colorHex).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        // ⚠️ Context Menu BURADAN SİLİNDİ, HomeView'a taşındı.
    }
}
