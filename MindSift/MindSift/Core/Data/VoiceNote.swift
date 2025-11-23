//
//  Voice<note.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import SwiftData

// Notun türünü belirleyen Enum
// Codable: Diske yazılabilmesi için gereklidir.
// CaseIterable: Listelerde tüm seçenekleri gösterebilmek için.
enum NoteType: String, Codable, CaseIterable {
    case meeting = "Toplantı"
    case task = "Görev"
    case idea = "Fikir"
    case diary = "Günlük"
    case unclassified = "Genel"
    
    // Her tipe uygun SF Symbol ikonu
    var iconName: String {
        switch self {
        case .meeting: return "calendar"
        case .task: return "checklist"
        case .idea: return "lightbulb"
        case .diary: return "book.closed"
        case .unclassified: return "recordingtape"
        }
    }
}

// MARK: - VoiceNote Model
// @Model makrosu bu sınıfı otomatik olarak veritabanı tablosuna dönüştürür.

@Model
final class VoiceNote {
    // Benzersiz kimlik (Primary Key)
    @Attribute(.unique) var id: UUID
    
    // Ses dosyasının adı (Tam yol yerine sadece dosya adını saklamak daha güvenlidir)
    var audioFileName: String
    
    // AI tarafından yazıya dökülmüş metin
    var transcription: String?
    
    // AI tarafından üretilen başlık
    var title: String?
    
    // Notun oluşturulma tarihi
    var createdAt: Date
    
    // Notun kategorisi
    var type: NoteType
    
    // Notun işlenip işlenmediği (Örn: Takvime eklendi mi?)
    var isProcessed: Bool
    
    // Başlatıcı (Constructor)
    init(id: UUID = UUID(),
         audioFileName: String,
         transcription: String? = nil,
         title: String? = "Yeni Kayıt",
         createdAt: Date = Date(),
         type: NoteType = .unclassified,
         isProcessed: Bool = false) {
        
        self.id = id
        self.audioFileName = audioFileName
        self.transcription = transcription
        self.title = title
        self.createdAt = createdAt
        self.type = type
        self.isProcessed = isProcessed
    }
}
