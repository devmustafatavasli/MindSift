//
//  SpeechManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import Speech
import Observation // 👈 YENİ

@Observable // 👈 ARTIK BU VAR
class SpeechManager {
    
    var isTranscribing: Bool = false
    var errorMessage: String?
    
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
    
    func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
        // 1. Türkçe dil desteği
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR")) else {
            self.errorMessage = "Bu cihazda Türkçe konuşma tanıma desteklenmiyor."
            completion(nil)
            return
        }
        
        // 2. Kullanılabilirlik kontrolü
        if !recognizer.isAvailable {
            self.errorMessage = "Konuşma tanıma şu an kullanılamıyor."
            completion(nil)
            return
        }
        
        DispatchQueue.main.async { self.isTranscribing = true }
        
        // 3. İstek oluştur
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = false
        
        // 4. İşlemi Başlat
        recognizer.recognitionTask(with: request) {
 result,
 error in
            DispatchQueue.main.async {
                self.isTranscribing = false
                
                if let error = error {
                    print("❌ Çeviri Hatası: \(error.localizedDescription)")
                    completion(nil)
                } else if let result = result,
                          result.isFinal {
                    print(
                        "📝 Çevrilen Metin: \(result.bestTranscription.formattedString)"
                    )
                    completion(result.bestTranscription.formattedString)
                }
            }
        }
    }
}
