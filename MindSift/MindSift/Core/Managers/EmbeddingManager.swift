//
//  EmbeddingManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 5.12.2025.
//

import Foundation
import CoreML
import Tokenizers
import Hub

actor EmbeddingManager {
    
    static let shared = EmbeddingManager()
    
    private var model: all_MiniLM_L6_v2?
    private var tokenizer: Tokenizer?
    
    // Durum takibi
    private var isModelLoaded = false
    private var isLoading = false // Çift yüklemeyi önlemek için kilit
    
    private init() {
    }
    
    private func loadModel() async {
        // Zaten yüklüyse veya yükleniyorsa dur
        if isModelLoaded || isLoading { return }
        isLoading = true
        
        do {
            // Simülatörde modeli yüklemeye bile çalışma, vakit kaybı
#if targetEnvironment(simulator)
            print(
                "⚠️ Simülatör Modu: CoreML modeli atlanıyor (Mock Data kullanılacak)."
            )
            // Tokenizer'ı yine de yükleyelim, o CPU'da çalışır
            self.tokenizer = try await AutoTokenizer
                .from(pretrained: "sentence-transformers/all-MiniLM-L6-v2")
            self.isModelLoaded = true
            isLoading = false
            return
#endif
            
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            self.model = try all_MiniLM_L6_v2(configuration: config)
            self.tokenizer = try await AutoTokenizer
                .from(pretrained: "sentence-transformers/all-MiniLM-L6-v2")
            
            self.isModelLoaded = true
            print("✅ Embedding Modeli ve Tokenizer hazır.")
        } catch {
            print("❌ Model yükleme hatası: \(error)")
        }
        
        isLoading = false
    }
    
    func generateEmbedding(from text: String) async -> [Float]? {
        // Yüklü değilse yükle
        if !isModelLoaded { await loadModel() }
        
        // ---------------------------------------------------------
        // 🚨 SİMÜLATÖR BYPASS 🚨
        // Simülatörde CoreML hatası almamak için rastgele vektör dönüyoruz.
        // Bu sayede uygulamanın geri kalanı (Kayıt, Veritabanı) test edilebilir.
#if targetEnvironment(simulator)
        print("⚠️ Simülatör: Fake (Rastgele) vektör üretildi.")
        // 384 boyutlu rastgele vektör
        return (0..<384).map { _ in Float.random(in: -0.1...0.1) }
#endif
        // ---------------------------------------------------------
        
        guard let model = model, let tokenizer = tokenizer else { return nil }
        
        do {
            let inputs = try tokenizer.encode(
                text: text,
                addSpecialTokens: true
            )
            let maxLength = 128
            var ids = inputs.map { Int64($0) }
            var mask = Array(repeating: Int64(1), count: ids.count)
            
            if ids.count > maxLength {
                ids = Array(ids.prefix(maxLength))
                mask = Array(mask.prefix(maxLength))
            } else {
                let paddingCount = maxLength - ids.count
                ids += Array(repeating: 0, count: paddingCount)
                mask += Array(repeating: 0, count: paddingCount)
            }
            
            let inputIDsMultiArray = try MLMultiArray(
                shape: [1, NSNumber(value: maxLength)],
                dataType: .int32
            )
            let attentionMaskMultiArray = try MLMultiArray(
                shape: [1, NSNumber(value: maxLength)],
                dataType: .int32
            )
            
            for (index, id) in ids.enumerated() {
                inputIDsMultiArray[index] = NSNumber(value: Int32(id))
                attentionMaskMultiArray[index] = NSNumber(
                    value: Int32(mask[index])
                )
            }
            
            let output = try model.prediction(
                input_ids: inputIDsMultiArray,
                attention_mask: attentionMaskMultiArray
            )
            return self.convertToFloatArray(output.embeddings)
            
        } catch {
            print("⚠️ Embedding oluşturulamadı: \(error)")
            return nil
        }
    }
    
    private func convertToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        let ptr = multiArray.dataPointer.bindMemory(
            to: Float.self,
            capacity: count
        )
        let buffer = UnsafeBufferPointer(start: ptr, count: count)
        return Array(buffer)
    }
}
