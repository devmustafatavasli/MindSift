//
//  VoiceNote.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import SwiftData

enum NoteType: String, Codable, CaseIterable {
    case meeting = "Toplantı"
    case task = "Görev"
    case email = "E-posta"
    case idea = "Fikir"
    case diary = "Günlük"
    case travel = "Seyahat"
    case unclassified = "Genel"
    
    var iconName: String {
        switch self {
        case .meeting: return "calendar"
        case .task: return "checklist"
        case .email: return "envelope.fill"
        case .idea: return "lightbulb"
        case .diary: return "book.closed"
        case .travel: return "airplane.departure"
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
    
    var smartIcon: String?
    var smartColor: String?
    
    // Metnin vektörel olarak sayısal karşılığını tutacağız.
    var embedding: [Float]?
    
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
         smartIcon: String? = nil,
         smartColor: String? = nil,
         embedding: [Float]? = nil,
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
        self.smartIcon = smartIcon
        self.smartColor = smartColor
        self.embedding = embedding
        self.createdAt = createdAt
        self.type = type
        self.isProcessed = isProcessed
    }
}
