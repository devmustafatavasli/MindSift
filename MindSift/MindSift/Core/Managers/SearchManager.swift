//
//  SearchManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 5.12.2025.
//

import Foundation
import SwiftData
import Accelerate
import Observation // 👈 YENİ

@Observable // 👈 ARTIK BU VAR
class SearchManager {
    
    // Eşik Değer
    private let similarityThreshold: Float = 0.4
    
    func search(query: String, notes: [VoiceNote], selectedType: NoteType?) async -> [VoiceNote] {
        
        // 1. Kategori Filtresi
        let typeFiltered = selectedType == nil ? notes : notes.filter {
            $0.type == selectedType
        }
        
        guard !query.isEmpty else { return typeFiltered }
        
        // 2. Vektör Oluştur
        let queryEmbedding = await EmbeddingManager.shared.generateEmbedding(from: query)
        
        // 3. Notları Puanla
        let scoredNotes: [(note: VoiceNote, score: Float)] = typeFiltered.compactMap { note in
            var score: Float = 0.0
            
            // A. Kelime Eşleşmesi
            let textMatch = (note.title?.localizedCaseInsensitiveContains(query) ?? false) ||
                            (note.transcription?.localizedCaseInsensitiveContains(query) ?? false)
            if textMatch { score += 1.0 }
            
            // B. Anlamsal Benzerlik
            if let noteVector = note.embedding, let queryVector = queryEmbedding {
                let similarity = cosineSimilarity(queryVector, noteVector)
                if similarity > 0 {
                    score += similarity
                }
            }
            
            return score > 0.3 ? (note, score) : nil
        }
        
        // 4. Sırala
        return scoredNotes
            .sorted { $0.score > $1.score }
            .map { $0.note }
    }
    
    // MARK: - Cosine Similarity
    private func cosineSimilarity(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
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
