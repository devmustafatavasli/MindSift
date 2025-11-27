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
    private let apiKey = Secrets.geminiAPIKey
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
            
        let is24Hour = UserDefaults.standard.object(
            forKey: "is24HourTime"
        ) as? Bool ?? true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = is24Hour ? "dd MMMM yyyy EEEE HH:mm" : "dd MMMM yyyy EEEE h:mm a"
        dateFormatter.locale = Locale(identifier: "tr_TR")
        let currentDateString = dateFormatter.string(from: Date())
            
        // 🧠 GELİŞMİŞ PROMPT
        let promptText = """
            Bugünün tarihi: \(currentDateString).
            
            GÖREV: Aşağıdaki metni bir "Kişisel Asistan" gibi analiz et. Metnin BİR EYLEM mi yoksa BİR ANI/KAYIT mı olduğunu tespit et.
            Metin: "\(text)"
            
            1. TÜR BELİRLEME:
               - Eğer birine bir şey göndermek, iletmek isteniyorsa -> 'E-posta'
               - Belirli bir zamanda bir yere gidilecekse -> 'Toplantı'
               - Yapılacak bir iş varsa -> 'Görev'
               - Bir gezi, anı, gözlem anlatılıyorsa -> 'Seyahat' veya 'Günlük'
               - Sadece bir fikir ise -> 'Fikir'
            
            2. ÇIKTI FORMATI (JSON):
            {
                "title": "Kısa, vurucu başlık",
                "summary": "İçeriğin özeti (Eğer bu bir e-postaysa, mailin amacını özetle)",
                "type": "E-posta | Toplantı | Görev | Fikir | Günlük | Seyahat | Genel",
                "priority": "Yüksek | Orta | Düşük",
                "event_date": "Eğer net bir tarih varsa ISO 8601 (YYYY-MM-DDTHH:mm:ss), yoksa null",
                "email_subject": "Eğer tür 'E-posta' ise uygun bir konu başlığı yaz, değilse null",
                "email_body": "Eğer tür 'E-posta' ise, son derece profesyonel ve nazik bir mail taslağı yaz. Gönderen kısmını boş bırak. Değilse null."
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
            
                // Debug: Ham veriyi yazdır
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📦 API Cevabı: \(rawString)")
                }
            
                do {
                    // Önce Hata Kontrolü
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

                    // Başarılı Cevap
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
