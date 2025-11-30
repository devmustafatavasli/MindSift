//
//  GeminiService.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation

// MARK: - Hata Modelleri
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

// Model Listesi (Hata durumunda debug için)
struct ModelListResponse: Codable {
    let models: [ModelInfo]?
}
struct ModelInfo: Codable {
    let name: String
    let displayName: String?
}

// MARK: - Gemini Servisi
class GeminiService {
    // API Anahtarını Secrets dosyasından alıyoruz
    private let apiKey = Secrets.geminiAPIKey
    
    // Model: Kararlı, hızlı ve ücretsiz kota dostu sürüm
    private let currentModel = "gemini-flash-latest"
    
    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(currentModel):generateContent"
    }
    
    // Ana Analiz Fonksiyonu
    func analyzeText(
        text: String,
        completion: @escaping (Result<AIAnalysisResult, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // 1. Kullanıcı Ayarlarına Göre Tarih Formatı
        let is24Hour = UserDefaults.standard.object(
            forKey: "is24HourTime"
        ) as? Bool ?? true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = is24Hour ? "dd MMMM yyyy EEEE HH:mm" : "dd MMMM yyyy EEEE h:mm a"
        dateFormatter.locale = Locale(identifier: "tr_TR")
        let currentDateString = dateFormatter.string(from: Date())
        
        // 2. Dinamik Prompt (Zeka)
        let promptText = """
        Bugünün tam tarihi ve saati: \(currentDateString).
        
        GÖREV: Aşağıdaki metni analiz et, sınıflandır ve ona uygun GÖRSEL bir kimlik (ikon ve renk) oluştur.
        Metin: "\(text)"
        
        1. TÜR VE AKSİYON:
           - E-posta, Toplantı, Görev, Fikir, Günlük, Seyahat, Genel türlerinden birini seç.
           - Varsa tarih, e-posta içeriği gibi detayları çıkar.
        
        2. GÖRSELLEŞTİRME (EN ÖNEMLİ KISIM):
           - suggested_icon: Apple SF Symbols kütüphanesinden metnin içeriğine EN UYGUN ikon ismini seç. (Örn: kahve için 'cup.and.saucer.fill', müzik için 'music.note', spor için 'sportscourt.fill', fikir için 'lightbulb.fill', toplantı için 'person.3.fill'). Sadece geçerli, var olan bir ikon ismi yaz.
           - suggested_color: İçeriğin duygusuna veya bağlamına uygun bir HEX renk kodu seç (Örn: Doğa için '#2ECC71', Acil için '#E74C3C', Sakinlik için '#3498DB', İş için '#5DADE2').
        
        3. ÇIKTI FORMATI (Sadece saf JSON döndür):
        {
            "title": "Kısa ve net başlık",
            "summary": "Tek cümlelik özet",
            "type": "E-posta | Toplantı | Görev | Fikir | Günlük | Seyahat | Genel",
            "priority": "Yüksek | Orta | Düşük",
            "event_date": "Varsa ISO 8601 formatında tarih (YYYY-MM-DDTHH:mm:ss), yoksa null",
            "email_subject": "E-posta ise konu, yoksa null",
            "email_body": "E-posta ise profesyonel içerik, yoksa null",
            "suggested_icon": "SF Symbol İsmi",
            "suggested_color": "#HEXKODU"
        }
        """
        
        // 3. İstek Oluşturma
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
        
        // 4. İstek Gönderme ve Cevabı İşleme
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
            
                // Debug: Gelen ham veriyi konsola bas
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📦 API Cevabı: \(rawString)")
                }
            
                do {
                    // Önce Google API Hatası var mı kontrol et
                    if let errorResponse = try? JSONDecoder().decode(
                        GeminiErrorResponse.self,
                        from: data
                    ),
                       let errorDetail = errorResponse.error {
                        print("🚨 GOOGLE API HATASI: \(errorDetail.message)")
                    
                        // Model bulunamadıysa (404), mevcut modelleri listele
                        if errorDetail.code == 404 {
                            self?.listAvailableModels()
                        }
                    
                        completion(
                            .failure(APIError.apiError(errorDetail.message))
                        )
                        return
                    }

                    // Başarılı Cevabı Çözümle
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
                    // Beklenmedik format (Dizi vb.) kontrolü
                    if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                        print(
                            "⚠️ Beklenmeyen Cevap Formatı: API bir DİZİ (Array) döndürdü."
                        )
                        print("İçerik: \(jsonArray)")
                        completion(
                            .failure(
                                APIError
                                    .apiError(
                                        "API beklenmedik şekilde bir dizi döndürdü."
                                    )
                            )
                        )
                    } else {
                        print("❌ JSON Decode Hatası: \(error)")
                        completion(.failure(error))
                    }
                }
            }.resume()
    }
    
    // Yardımcı: Mevcut Modelleri Listele
    private func listAvailableModels() {
        let listURLString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        guard let url = URL(string: listURLString) else { return }
        
        print("📋 Modeller listeleniyor...")
        URLSession.shared.dataTask(with: url) {
 data,
 _,
            _ in
            guard let data = data,
                  let listResponse = try? JSONDecoder().decode(ModelListResponse.self, from: data) else {
                return
            }
            
            print("\n📋 KULLANILABİLİR MODELLER:")
            listResponse.models?.forEach { model in
                if model.name
                    .contains("gemini") { // Sadece Gemini modellerini göster
                    print("- \(model.name)")
                }
            }
            print("--------------------------\n")
        }.resume()
    }
}
