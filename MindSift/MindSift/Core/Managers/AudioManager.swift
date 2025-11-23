//
//  AudioManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import Combine
import AVFoundation

// MARK: - Audio Manager
// Uygulamanın ses kayıt işlemlerini yöneten merkezi sınıf.
// NSObject: AVAudioRecorderDelegate olabilmek için gereklidir.
// ObservableObject: UI'ın (Arayüzün) bu sınıftaki değişiklikleri dinleyebilmesi için.

class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    
    // UI'ın anlık takip edeceği değişkenler (@Published)
    @Published var isRecording: Bool = false
    @Published var audioURL: URL? // Kaydedilen son dosyanın adresi
    @Published var errorMessage: String? // Hata olursa kullanıcıya göstermek için
    
    private var audioRecorder: AVAudioRecorder?
    
    // Uygulama açıldığında izinleri kontrol et
    override init() {
        super.init()
        checkPermissions()
    }
    
    // MARK: - Kayıt İşlemleri
    
    func startRecording() {
        // 1. Ses oturumunu ayarla (Hem kayıt yap hem de çalınabilsin)
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true)
            
            // 2. Dosya ismini oluştur (Benzersiz olması için tarih kullanıyoruz)
            let fileName = "voice_note_\(Date().timeIntervalSince1970).m4a"
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            
            // 3. Kalite Ayarları (M4A - AAC formatı idealdir)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // 4. Kaydediciyi başlat
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            // UI'ı güncelle (Ana thread'de yapılmalı)
            DispatchQueue.main.async {
                self.isRecording = true
                self.errorMessage = nil
            }
            print("🎙️ Kayıt başladı: \(url.lastPathComponent)")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Kayıt başlatılamadı: \(error.localizedDescription)"
            }
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
            // Kayıt bitince dosya URL'ini sakla
            self.audioURL = self.audioRecorder?.url
        }
        print("🛑 Kayıt durdu.")
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    // Mikrofon izni kontrolü
    func checkPermissions() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                break
            case .denied:
                DispatchQueue.main.async {
                    self.errorMessage = "Mikrofon izni reddedildi. Ayarlardan açmanız gerekiyor."
                }
            case .undetermined:
                AVAudioApplication.requestRecordPermission { allowed in
                    if !allowed {
                        DispatchQueue.main.async {
                            self.errorMessage = "Mikrofon izni verilmedi."
                        }
                    }
                }
            @unknown default:
                break
            }
        } else {
            // Fallback for iOS versions prior to 17.0
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                break
            case .denied:
                DispatchQueue.main.async {
                    self.errorMessage = "Mikrofon izni reddedildi. Ayarlardan açmanız gerekiyor."
                }
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    if !allowed {
                        DispatchQueue.main.async {
                            self.errorMessage = "Mikrofon izni verilmedi."
                        }
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    // Dosyaların kaydedileceği klasörü bulur
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // AVAudioRecorderDelegate: Kayıt beklenmedik şekilde kesilirse (örn: telefon çalarsa)
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
        }
    }
}

