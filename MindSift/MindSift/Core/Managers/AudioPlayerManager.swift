//
//  AudioPlayerManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 1.12.2025.
//

import Foundation
import AVFoundation
import Observation

@Observable
class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    
    func setupPlayer(audioFileName: String) {
        // 👇 GÜNCELLEME: Dosya yolunu StorageManager bulsun
        let url = StorageManager.shared.getFileURL(fileName: audioFileName)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            self.duration = audioPlayer?.duration ?? 0
            self.currentTime = 0
            self.isPlaying = false
            
            print("🎵 Player hazırlandı. Süre: \(self.duration)")
        } catch {
            print("❌ Ses dosyası bulunamadı veya bozuk: \(url.path)")
        }
    }
    
    func playPause() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            stopTimer()
            isPlaying = false
        } else {
            player.play()
            startTimer()
            isPlaying = true
        }
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func stop() {
        audioPlayer?.stop()
        stopTimer()
        isPlaying = false
        currentTime = 0
        audioPlayer?.currentTime = 0
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
        currentTime = 0
        player.currentTime = 0
    }
}
