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
    
    // Ses dosyasını sadece hazırla (OYNATMA)
    func setupPlayer(audioFileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(audioFileName)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay() // Sadece buffer'a alır, çalmaz
            
            // UI için süre bilgisini al
            self.duration = audioPlayer?.duration ?? 0
            self.currentTime = 0
            self.isPlaying = false // Başlangıçta duruyor olarak işaretle
            
        } catch {
            print("Ses dosyası yüklenemedi: \(error.localizedDescription)")
        }
    }
    
    // Oynat / Duraklat (Kullanıcı basınca çalışır)
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
    
    // İlerleme çubuğu (Slider) değişince
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // Zamanlayıcı (Slider'ı ilerletmek için)
    private func startTimer() {
        // Eski timer varsa iptal et
        stopTimer()
        timer = Timer
            .scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else {
                    return
                }
                self.currentTime = player.currentTime
            }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Ses bitince
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        isPlaying = false
        stopTimer()
        currentTime = 0 // Başa sar
        player.currentTime = 0
    }
    
    // Uygulama arka plana atılınca vb. durumlar için temizlik
    func stop() {
        audioPlayer?.stop()
        stopTimer()
        isPlaying = false
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
