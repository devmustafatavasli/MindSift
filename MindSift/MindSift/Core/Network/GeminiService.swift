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

struct ModelListResponse: Codable {
    let models: [ModelInfo]?
}
struct ModelInfo: Codable {
    let name: String
    let displayName: String?
}

class GeminiService {
    // ⚠️ Secrets.swift kullanıyorsan oradan çek, yoksa buraya yapıştır.
    private let apiKey = Secrets.geminiAPIKey
    
    // Model: Kararlı sürüm
    private let currentModel = "gemini-flash-latest"
    
    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(currentModel):generateContent"
    }
    
    func analyzeText(
        text: String,
        completion: @escaping (Result<AIAnalysisResult, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // 🗓️ GÜÇLENDİRİLMİŞ TARİH MANTIĞI
        // AI'ya sadece tarihi değil, gün ismini de veriyoruz (Örn: "24 Kasım 2025 Pazartesi")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy EEEE HH:mm"
        dateFormatter.locale = Locale(identifier: "tr_TR")
        let currentDateString = dateFormatter.string(from: Date())
        
        let promptText = """
        Bugünün tam tarihi ve saati: \(currentDateString).
        
        Aşağıdaki metni bir asistan gibi analiz et.
        Metin: "\(text)"
        
        GÖREVLER:
        1. İçerikten bir başlık ve özet çıkar.
        2. Metindeki niyetin tipini belirle (Toplantı, Görev, vb.).
        3. Metinde BELİRGİN bir zaman ifadesi var mı? (Örn: "Yarın", "Haftaya Salı", "Akşam 5'te", "25'inde").
        4. Eğer zaman ifadesi varsa, verdiğim bugünün tarihini referans alarak o günün tarihini hesapla.
        
        YANIT FORMATI (Sadece JSON):
        {
            "title": "Kısa başlık",
            "summary": "Tek cümlelik özet",
            "type": "Toplantı | Görev | Fikir | Günlük | Genel",
            "priority": "Yüksek | Orta | Düşük",
            "event_date": "Hesapladığın tarihi ISO 8601 formatında yaz (YYYY-MM-DDTHH:mm:ss). Eğer metinde hiç zaman yoksa null yap."
        }
        """
        
        let requestBody = GeminiRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: promptText)])],
            generationConfig: GeminiGenerationConfig(
                responseMimeType: "application/json"
            )
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
        
        URLSession.shared
            .dataTask(with: request) {
 [weak self] data,
 response,
 error in
                if let error = error {
                    print("❌ Ağ Hatası: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
            
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
            
                // Debug için ham veriyi yazdır
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📦 API Cevabı: \(rawString)")
                }
            
                do {
                    if let errorResponse = try? JSONDecoder().decode(
                        GeminiErrorResponse.self,
                        from: data
                    ),
                       let errorDetail = errorResponse.error {
                        print("🚨 GOOGLE API HATASI: \(errorDetail.message)")
                        if errorDetail.code == 404 {
                            self?.listAvailableModels()
                        }
                        completion(
                            .failure(APIError.apiError(errorDetail.message))
                        )
                        return
                    }

                    let apiResponse = try JSONDecoder().decode(
                        GeminiResponse.self,
                        from: data
                    )
                
                    if let jsonString = apiResponse.candidates?.first?.content.parts.first?.text,
                       let jsonData = jsonString.data(using: .utf8) {
                    
                        let analysis = try JSONDecoder().decode(
                            AIAnalysisResult.self,
                            from: jsonData
                        )
                        completion(.success(analysis))
                    
                    } else {
                        completion(.failure(APIError.decodingError))
                    }
                } catch {
                    if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                        print("⚠️ Dizi formatı hatası.")
                        completion(
                            .failure(APIError.apiError("API dizi döndürdü."))
                        )
                    } else {
                        print("❌ JSON Decode Hatası: \(error)")
                        completion(.failure(error))
                    }
                }
            }.resume()
    }
    
    private func listAvailableModels() {
        let listURLString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        guard let url = URL(string: listURLString) else { return }
        URLSession.shared.dataTask(with: url) {
 data,
            _,
            _ in
            guard let data = data,
                  let listResponse = try? JSONDecoder().decode(ModelListResponse.self, from: data) else {
                return
            }
            print("\n📋 MODELLER:")
            listResponse.models?.forEach { print("- \($0.name)") }
        }.resume()
    }
}
