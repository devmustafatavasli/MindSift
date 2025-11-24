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

// MARK: - Bizim Uygulamanın Kullanacağı Sonuç Modeli
struct AIAnalysisResult: Codable {
    let title: String
    let summary: String
    let type: String // "Toplantı", "Görev", "Fikir" vb.
    let priority: String // "Yüksek", "Orta", "Düşük"
}
