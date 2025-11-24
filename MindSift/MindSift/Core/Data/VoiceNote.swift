//
//  Voice<note.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import SwiftData

enum NoteType: String, Codable, CaseIterable {
    case meeting = "Toplantı"
    case task = "Görev"
    case idea = "Fikir"
    case diary = "Günlük"
    case unclassified = "Genel"
    
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

@Model
final class VoiceNote {
    @Attribute(.unique) var id: UUID
    var audioFileName: String
    var transcription: String?
    var title: String?
    var summary: String?
    var priority: String?
    var createdAt: Date
    var type: NoteType
    var isProcessed: Bool
    
    init(id: UUID = UUID(),
         audioFileName: String,
         transcription: String? = nil,
         title: String? = "Yeni Kayıt",
         summary: String? = nil,
         priority: String? = "Düşük",
         createdAt: Date = Date(),
         type: NoteType = .unclassified,
         isProcessed: Bool = false) {
        
        self.id = id
        self.audioFileName = audioFileName
        self.transcription = transcription
        self.title = title
        self.summary = summary
        self.priority = priority
        self.createdAt = createdAt
        self.type = type
        self.isProcessed = isProcessed
    }
}
