//
//  SearchManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 5.12.2025.
//

//
//  SearchManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 5.12.2025.
//

import Foundation
import SwiftData
import Accelerate // ⚡️ Apple'ın matematik motoru
import Combine

class SearchManager: ObservableObject {
    
    // Eşik Değer (Threshold): 0.6 üzerindeki benzerlikler "alakalı" sayılır.
    private let similarityThreshold: Float = 0.4
    
    /// Hibrit Arama: Hem Kelime (Keyword) hem de Anlam (Semantic) araması
    func search(query: String, notes: [VoiceNote], selectedType: NoteType?) async -> [VoiceNote] {
        
        // 1. Kategori Filtresi
        let typeFiltered = selectedType == nil ? notes : notes.filter {
            $0.type == selectedType
        }
        
        guard !query.isEmpty else { return typeFiltered }
        
        // 2. Kullanıcının sorgusunun vektörünü oluştur (Asıl Büyü Burada ✨)
        let queryEmbedding = await EmbeddingManager.shared.generateEmbedding(
            from: query
        )
        
        // 3. Notları Puanla
        let scoredNotes: [(
            note: VoiceNote,
            score: Float
        )] = typeFiltered.compactMap { note in
            var score: Float = 0.0
            
            // A. Kelime Eşleşmesi (Eski yöntem - hala değerli)
            let textMatch = (note.title?.localizedCaseInsensitiveContains(query) ?? false) ||
            (
                note.transcription?
                    .localizedCaseInsensitiveContains(query) ?? false
            )
            if textMatch { score += 1.0 } // Kelime geçiyorsa tam puan
            
            // B. Anlamsal Benzerlik (Yeni yöntem)
            if let noteVector = note.embedding, let queryVector = queryEmbedding {
                let similarity = cosineSimilarity(queryVector, noteVector)
                // Sadece pozitif ve anlamlı benzerlikleri ekle
                if similarity > 0 {
                    score += similarity
                }
            }
            
            // Hiç puan alamadıysa ele
            return score > 0.3 ? (note, score) : nil
        }
        
        // 4. Puana Göre Sırala (En alakalı en üstte)
        return scoredNotes
            .sorted { $0.score > $1.score }
            .map { $0.note }
    }
    
    // MARK: - Cosine Similarity (Kosinüs Benzerliği)
    // Accelerate (vDSP) kullanarak ultra hızlı hesaplama
    private func cosineSimilarity(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else { return 0.0 }
        let count = vDSP_Length(vectorA.count)
        
        // Dot Product (Nokta Çarpımı)
        var dotProduct: Float = 0.0
        vDSP_dotpr(vectorA, 1, vectorB, 1, &dotProduct, count)
        
        // Norm (Büyüklük) Hesaplama
        var normA: Float = 0.0
        vDSP_svesq(vectorA, 1, &normA, count) // Kareler toplamı
        normA = sqrt(normA)
        
        var normB: Float = 0.0
        vDSP_svesq(vectorB, 1, &normB, count)
        normB = sqrt(normB)
        
        // Payda 0 olamaz
        if normA == 0 || normB == 0 { return 0.0 }
        
        return dotProduct / (normA * normB)
    }
}
