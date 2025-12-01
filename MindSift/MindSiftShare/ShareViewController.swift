//
//  ShareViewController.swift
//  MindSiftShare
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import UIKit
import Social
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Paylaşılan içeriği al
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.closeExtension()
            return
        }
        
        // 2. Ses dosyası olup olmadığını kontrol et
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil) { (item, error) in
                if let url = item as? URL {
                    self.saveAudioFile(sourceUrl: url)
                }
            }
        } else {
            closeExtension()
        }
    }

    private func saveAudioFile(sourceUrl: URL) {
        // App Group Kimliği (Ana uygulamadakiyle BİREBİR AYNI olmalı)
        let appGroupIdentifier = "group.com.devmustafatavasli.MindSift" // <-- BURAYI KENDİ GRUP ID'N İLE DEĞİŞTİR
        
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("Hata: App Group bulunamadı.")
            closeExtension()
            return
        }
        
        // 3. Dosyayı Ortak Klasöre Kopyala
        let fileName = "shared_\(Date().timeIntervalSince1970).m4a"
        let destinationUrl = fileContainer.appendingPathComponent(fileName)
        
        do {
            // Güvenlik kapsamı (Security Scoped Resource) erişimi gerekebilir
            let secured = sourceUrl.startAccessingSecurityScopedResource()
            try FileManager.default.copyItem(at: sourceUrl, to: destinationUrl)
            if secured { sourceUrl.stopAccessingSecurityScopedResource() }
            
            // 4. Veritabanına Kaydet
            saveToDatabase(audioFileName: fileName, containerURL: fileContainer)
            
        } catch {
            print("Dosya kopyalama hatası: \(error)")
            closeExtension()
        }
    }
    
    private func saveToDatabase(audioFileName: String, containerURL: URL) {
        do {
            // SwiftData Konteynerini Manuel Başlat (Shared)
            let storeURL = containerURL.appendingPathComponent("MindSift.sqlite")
            let config = ModelConfiguration(url: storeURL, allowsSave: true)
            let container = try ModelContainer(for: VoiceNote.self, configurations: config)
            let context = ModelContext(container)
            
            // Yeni Not Oluştur
            let newNote = VoiceNote(
                audioFileName: audioFileName,
                transcription: nil, // Henüz yok
                title: "Dışarıdan Gelen Kayıt",
                summary: "Analiz için uygulamayı açın...",
                type: .unclassified,
                isProcessed: false // Ana uygulama açılınca bunu görüp işleyecek
            )
            
            context.insert(newNote)
            try context.save()
            print("✅ Paylaşılan dosya veritabanına eklendi.")
            
            // İşlem bitti, eklentiyi kapat
            closeExtension()
            
        } catch {
            print("Veritabanı hatası: \(error)")
            closeExtension()
        }
    }
    
    private func closeExtension() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
