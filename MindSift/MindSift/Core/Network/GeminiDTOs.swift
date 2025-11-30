//
//  GeminiDTOs.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation

// MARK: - İstek (Request)
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let responseMimeType: String
}

// MARK: - Cevap (Response)
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
}

struct AIAnalysisResult: Codable {
    let title: String
    let summary: String
    let type: String
    let priority: String
    let event_date: String?
    let email_subject: String?
    let email_body: String?
    
    let suggested_icon: String?
    let suggested_color: String?
}
