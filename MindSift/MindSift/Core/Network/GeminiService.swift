//
//  GeminiService.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case apiError(String)
}

struct GeminiErrorResponse: Codable {
    let error: GeminiErrorDetail?
}

struct GeminiErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String?
}

// Model listesi (Array dönerse bunu yakalayacağız)
struct ModelListResponse: Codable {
    let models: [ModelInfo]?
}
struct ModelInfo: Codable {
    let name: String
    let displayName: String?
}

class GeminiService {
    private let apiKey = Secrets.geminiAPIKey
    
    private let currentModel = "gemini-flash-latest"
    
    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(currentModel):generateContent"
    }
    
    func analyzeText(text: String, completion: @escaping (Result<AIAnalysisResult, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let promptText = """
        Aşağıdaki metni analiz et ve SADECE şu JSON formatında yanıt ver, başka hiçbir şey yazma:
        {
            "title": "Kısa başlık",
            "summary": "Tek cümlelik özet",
            "type": "Şunlardan biri: Toplantı, Görev, Fikir, Günlük, Genel",
            "priority": "Şunlardan biri: Yüksek, Orta, Düşük"
        }
        
        Metin: "\(text)"
        """
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: promptText)])],
            generationConfig: GeminiGenerationConfig(responseMimeType: "application/json")
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        print("📡 Gemini API İsteği Gönderiliyor (\(currentModel))...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Ağ Hatası: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            // 📦 HAM CEVABI YAZDIR (Debug için en önemli kısım)
            if let rawString = String(data: data, encoding: .utf8) {
                print("📦 API'dan Gelen Ham Cevap: \(rawString)")
            }
            
            do {
                // 1. Önce bunun bir HATA olup olmadığına bakalım
                if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data),
                   let errorDetail = errorResponse.error {
                    print("🚨 GOOGLE API HATASI: \(errorDetail.message)")
                    completion(.failure(APIError.apiError(errorDetail.message)))
                    return
                }

                // 2. Cevap beklediğimiz formatta mı (GeminiResponse)?
                let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                if let jsonString = apiResponse.candidates?.first?.content.parts.first?.text,
                   let jsonData = jsonString.data(using: .utf8) {
                    
                    let analysis = try JSONDecoder().decode(AIAnalysisResult.self, from: jsonData)
                    completion(.success(analysis))
                    
                } else {
                    print("⚠️ Yapısal Hata: Candidates boş veya metin yok.")
                    completion(.failure(APIError.decodingError))
                }
            } catch {
                // 3. Eğer yukarıdakiler patlarsa ve gelen bir DİZİ (Array) ise:
                if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                     print("⚠️ Beklenmeyen Cevap Formatı: API bir DİZİ (Array) döndürdü.")
                     print("İçerik: \(jsonArray)")
                     completion(.failure(APIError.apiError("API beklenmedik şekilde bir dizi döndürdü.")))
                } else {
                    print("❌ JSON Decode Hatası: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
