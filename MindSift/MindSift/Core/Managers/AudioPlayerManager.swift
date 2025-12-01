//
//  AudioPlayerManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 1.12.2025.
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    // 👇 GÜNCELLEME: Kendi App Group ID'ni buraya yaz
    private let appGroupIdentifier = "group.com.devmustafatavasli.MindSift"
    
    func setupPlayer(audioFileName: String) {
        // 1. Önce standart Documents klasörüne bak
        var url = getDocumentsDirectory().appendingPathComponent(audioFileName)
        
        // 2. Eğer dosya orada yoksa, App Group klasörüne bak (Share Extension dosyaları burada)
        if !FileManager.default.fileExists(atPath: url.path) {
            if let sharedUrl = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            ) {
                let potentialUrl = sharedUrl.appendingPathComponent(
                    audioFileName
                )
                if FileManager.default.fileExists(atPath: potentialUrl.path) {
                    url = potentialUrl
                }
            }
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            self.duration = audioPlayer?.duration ?? 0
            self.currentTime = 0
            self.isPlaying = false
        } catch {
            print("Ses dosyası bulunamadı veya bozuk: \(url.path)")
        }
    }
    
    // ... (Geri kalan fonksiyonlar: playPause, seek, startTimer, stopTimer, audioPlayerDidFinishPlaying, stop AYNI KALACAK)
    
    func playPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause(); stopTimer(); isPlaying = false
        } else {
            player.play(); startTimer(); isPlaying = true
        }
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer
            .scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.currentTime = self?.audioPlayer?.currentTime ?? 0
            }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        isPlaying = false; stopTimer(); currentTime = 0; player.currentTime = 0
    }
    
    func stop() {
        audioPlayer?.stop(); stopTimer(); isPlaying = false
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
