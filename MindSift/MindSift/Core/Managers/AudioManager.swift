//
//  AudioManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import AVFoundation
import ActivityKit
import Observation

@Observable
class AudioManager: NSObject, AVAudioRecorderDelegate {
    
    var isRecording: Bool = false
    var audioURL: URL?
    var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var currentActivity: Activity<MindSiftAttributes>?
    
    override init() {
        super.init()
        checkPermissions()
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopRecording), name: NSNotification.Name("StopRecordingFromIsland"), object: nil)
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try audioSession.setActive(true)
            
            // 👇 GÜNCELLEME: Dosya yolunu StorageManager'dan alıyoruz
            let url = StorageManager.shared.getNewRecordingURL()
            
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
                self.startLiveActivity()
            }
            print("🎙️ Kayıt başladı: \(url.lastPathComponent)")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Kayıt başlatılamadı: \(error.localizedDescription)"
            }
        }
    }
    
    @objc func stopRecording() {
        audioRecorder?.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.audioURL = self.audioRecorder?.url
            self.stopLiveActivity()
        }
        print("🛑 Kayıt durdu.")
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity() {
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
                dismissalPolicy: .default
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
    
    func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        if !flag { stopRecording() }
    }
}
