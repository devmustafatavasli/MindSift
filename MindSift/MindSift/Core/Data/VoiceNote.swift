//
//  Voice<note.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import SwiftData

enum NoteType: String, Codable, CaseIterable {
    case meeting = "Toplantı" // Takvim aksiyonu
    case task = "Görev"       // Checklist aksiyonu
    case email = "E-posta"    // Mail aksiyonu (YENİ)
    case idea = "Fikir"       // Sadece Kayıt
    case diary = "Günlük"     // Sadece Kayıt (San Francisco örneği)
    case travel = "Seyahat"   // Sadece Kayıt (YENİ)
    case unclassified = "Genel"
    
    var iconName: String {
        switch self {
        case .meeting: return "calendar"
        case .task: return "checklist"
        case .email: return "envelope.fill"
        case .idea: return "lightbulb"
        case .diary: return "book.closed"
        case .travel: return "airplane.departure" // Seyahat için özel ikon
        case .unclassified: return "recordingtape"
        }
    }
}

@Model
final class VoiceNote {
    @Attribute(.unique) var id: UUID
    var audioFileName: String
    var transcription: String?
    var title: String?
    var summary: String?
    var priority: String?
    var eventDate: Date?
    
    var emailSubject: String?
    var emailBody: String?
    
    var createdAt: Date
    var type: NoteType
    var isProcessed: Bool
    
    init(id: UUID = UUID(),
         audioFileName: String,
         transcription: String? = nil,
         title: String? = "Yeni Kayıt",
         summary: String? = nil,
         priority: String? = "Düşük",
         eventDate: Date? = nil,
         emailSubject: String? = nil,
         emailBody: String? = nil,
         createdAt: Date = Date(),
         type: NoteType = .unclassified,
         isProcessed: Bool = false) {
        
        self.id = id
        self.audioFileName = audioFileName
        self.transcription = transcription
        self.title = title
        self.summary = summary
        self.priority = priority
        self.eventDate = eventDate
        self.emailSubject = emailSubject
        self.emailBody = emailBody
        self.createdAt = createdAt
        self.type = type
        self.isProcessed = isProcessed
    }
}
