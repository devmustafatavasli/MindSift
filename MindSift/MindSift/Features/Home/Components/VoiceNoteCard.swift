//
//  VoiceNoteCard.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//

import SwiftUI

struct VoiceNoteCard: View {
    let note: VoiceNote
    
    // 🎨 AKILLI RENK MANTIĞI
    // Eğer AI özel bir renk seçtiyse onu kullan, yoksa kategori rengine dön.
    var accentColor: Color {
        if let hex = note.smartColor {
            return Color(hex: hex)
        }
        
        switch note.type {
        case .meeting: return DesignSystem.Colors.primaryBlue
        case .task: return DesignSystem.Colors.accentOrange
        case .email: return .green
        case .idea: return DesignSystem.Colors.primaryPurple
        case .diary: return DesignSystem.Colors.accentPink
        case .travel: return .cyan
        default: return .gray
        }
    }
    
    // 🎙️ AKILLI İKON MANTIĞI
    // Eğer AI özel bir ikon seçtiyse onu kullan, yoksa kategori ikonunu kullan.
    var iconName: String {
        note.smartIcon ?? note.type.iconName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // ÜST KISIM: İkon ve Başlık
            HStack(alignment: .top) {
                // İkon Kutusu
                ZStack {
                    Circle()
                        .fill(
                            accentColor.opacity(0.1)
                        ) // Akıllı renk arka planı
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    
                    Image(systemName: iconName) // Akıllı ikon
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(accentColor) // Akıllı renk
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(note.title ?? "İsimsiz Not")
                        .font(DesignSystem.Typography.headline())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(
                            note.createdAt
                                .formatted(date: .numeric, time: .shortened)
                        )
                        
                        if let priority = note.priority, priority == "Yüksek" {
                            Text("•")
                            Text(priority)
                                .foregroundStyle(DesignSystem.Colors.accentPink)
                                .fontWeight(.bold)
                        }
                    }
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            
            // ORTA KISIM: Özet
            if let summary = note.summary {
                Text(summary)
                    .font(DesignSystem.Typography.subheadline())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .padding(.leading, 4)
            }
            
            // ALT KISIM: Etkinlik Tarihi (Varsa)
            if let eventDate = note.eventDate {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .symbolRenderingMode(.hierarchical)
                    Text(
                        eventDate
                            .formatted(date: .abbreviated, time: .shortened)
                    )
                }
                .font(DesignSystem.Typography.caption())
                .fontWeight(.medium)
                .foregroundStyle(accentColor) // Tarih de akıllı renge uyar
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .liquidGlass() // Liquid efekti
    }
}
