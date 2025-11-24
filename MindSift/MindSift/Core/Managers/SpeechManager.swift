//
//  SpeechManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//


import Foundation
import Combine
import Speech

// MARK: - Speech Manager
// Sadece tek bir işi var: Verilen ses dosyasını metne çevirmek.
// Clean Architecture: Kayıt işi AudioManager'da, Çeviri işi burada.

class SpeechManager: ObservableObject {
    
    // İşlem durumunu takip etmek için
    @Published var isTranscribing: Bool = false
    @Published var errorMessage: String?
    
    // İzinleri kontrol et
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Konuşma tanıma izni verildi.")
                case .denied:
                    self.errorMessage = "Konuşma tanıma izni reddedildi."
                case .restricted, .notDetermined:
                    self.errorMessage = "Konuşma tanıma izni bekleniyor."
                @unknown default:
                    break
                }
            }
        }
    }
    
    // Ana Fonksiyon: Dosya URL'ini al, Metni ver
    func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
        
        // 1. Türkçe dil desteğiyle tanı (Cihaz diline göre ayarlayabiliriz)
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR")) else {
            self.errorMessage = "Bu cihazda Türkçe konuşma tanıma desteklenmiyor."
            completion(nil)
            return
        }
        
        // 2. Dosyanın okunabilir olduğunu kontrol et
        if !recognizer.isAvailable {
            self.errorMessage = "Konuşma tanıma şu an kullanılamıyor."
            completion(nil)
            return
        }
        
        DispatchQueue.main.async { self.isTranscribing = true }
        
        // 3. İstek oluştur (Cihaz içi işleme öncelikli)
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false // Sadece son sonucu istiyoruz
        request.requiresOnDeviceRecognition = false // İnternet varsa daha iyi sonuç için sunucu kullanabilir
        
        // 4. İşlemi Başlat
        recognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                self.isTranscribing = false
                
                if let error = error {
                    print("❌ Çeviri Hatası: \(error.localizedDescription)")
                    // Hata olsa bile nil dön, akış bozulmasın
                    completion(nil)
                } else if let result = result, result.isFinal {
                    // SONUÇ BAŞARILI
                    print("📝 Çevrilen Metin: \(result.bestTranscription.formattedString)")
                    completion(result.bestTranscription.formattedString)
                }
            }
        }
    }
}
