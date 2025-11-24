//
//  AudioManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import AVFoundation
import ActivityKit // <-- YENİ: Ada için gerekli
import Combine

class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    
    @Published var isRecording: Bool = false
    @Published var audioURL: URL?
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    
    // Live Activity Referansı
    private var currentActivity: Activity<MindSiftAttributes>?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession
                .setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.defaultToSpeaker, .allowBluetooth]
                )
            try audioSession.setActive(true)
            
            let fileName = "voice_note_\(Date().timeIntervalSince1970).m4a"
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.errorMessage = nil
                // 👇 YENİ: Kayıt başlayınca adayı başlat
                self.startLiveActivity()
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
            self.audioURL = self.audioRecorder?.url
            // 👇 YENİ: Kayıt bitince adayı kapat
            self.stopLiveActivity()
        }
        print("🛑 Kayıt durdu.")
    }
    
    // MARK: - Live Activity Yönetimi 🏝️
    
    private func startLiveActivity() {
        // Live Activity verilerini hazırla
        let attributes = MindSiftAttributes(activityName: "Ses Kaydı")
        let contentState = MindSiftAttributes.ContentState(
            status: "Dinliyor...",
            timer: Date()
        )
        
        do {
            let activity = try Activity<MindSiftAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
            print("🏝️ Dynamic Island Başlatıldı: \(activity.id)")
        } catch {
            print("❌ Live Activity Hatası: \(error.localizedDescription)")
        }
    }
    
    private func stopLiveActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = MindSiftAttributes.ContentState(
            status: "Kaydedildi",
            timer: Date()
        )
        
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default // Hemen kapatma, sonucu biraz göster
            )
            self.currentActivity = nil
            print("🏝️ Dynamic Island Sonlandırıldı.")
        }
    }
    
    // MARK: - Helper & Permissions
    
    func checkPermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: break
        case .denied:
            DispatchQueue.main
                .async { self.errorMessage = "Mikrofon izni reddedildi." }
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                if !allowed {
                    DispatchQueue.main
                        .async {
                            self.errorMessage = "Mikrofon izni verilmedi."
                        }
                }
            }
        @unknown default: break
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        if !flag { stopRecording() }
    }
}

