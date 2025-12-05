//
//  SearchManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 5.12.2025.
//

import Foundation
import SwiftData
import Accelerate // ⚡️ Apple'ın yüksek performanslı matematik kütüphanesi
import Combine

// MARK: - Search Manager
// Hibrit Arama Motoru: Hem klasik metin (Keyword) hem de yapay zeka (Vector) aramasını yönetir.
// Akademik Değer: "Apple Accelerate framework'ü kullanılarak cihaz üzerinde yüksek performanslı Cosine Similarity hesaplaması."

class SearchManager: ObservableObject {
    
    // Şimdilik sadece klasik aramayı buraya taşıyoruz,
    // Bir sonraki adımda Vektör Arama yeteneği eklenecek.
    
    /// Hibrit Arama Fonksiyonu
    /// - Parameters:
    ///   - query: Kullanıcının yazdığı metin
    ///   - notes: Veritabanındaki tüm notlar
    ///   - selectedType: Varsa kategori filtresi
    /// - Returns: Filtrelenmiş ve sıralanmış notlar
    func search(query: String, notes: [VoiceNote], selectedType: NoteType?) -> [VoiceNote] {
        
        // 1. Kategori Filtresi (Varsa uygula)
        let typeFiltered = selectedType == nil ? notes : notes.filter { $0.type == selectedType }
        
        // 2. Arama Metni Boşsa Hepsini Dön
        guard !query.isEmpty else {
            return typeFiltered
        }
        
        // 3. Klasik Arama (Keyword Search)
        // Kullanıcı tam kelimeyi yazarsa kesin bulsun diye bunu tutuyoruz.
        let keywordResults = typeFiltered.filter { note in
            let titleMatch = note.title?.localizedCaseInsensitiveContains(query) ?? false
            let contentMatch = note.transcription?.localizedCaseInsensitiveContains(query) ?? false
            let summaryMatch = note.summary?.localizedCaseInsensitiveContains(query) ?? false
            
            return titleMatch || contentMatch || summaryMatch
        }
        
        // ⚠️ TODO: Buraya Semantic Search (Vektör Araması) eklenecek.
        // Semantic sonuçlar ile Keyword sonuçlarını birleştirip (Re-ranking) döndüreceğiz.
        
        return keywordResults
    }
    
    // MARK: - Gelecek Hazırlığı: Cosine Similarity
    // İki vektör arasındaki açıyı (benzerliği) hesaplar.
    // 1.0 = Tamamen aynı anlam, 0.0 = Alakasız, -1.0 = Zıt anlam
    func cosineSimilarity(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        // Accelerate kütüphanesi (vDSP) kullanılarak işlemciyi yormadan hesaplanır.
        // CoreML entegrasyonundan sonra burayı dolduracağız.
        return 0.0
    }
}
