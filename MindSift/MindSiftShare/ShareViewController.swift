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
        
        // 1. Gelen içeriği kontrol et
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            closeExtension()
            return
        }
        
        // 2. Ses dosyası mı?
        if itemProvider
            .hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            itemProvider
                .loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil) { (
                    item,
                    error
                ) in
                    if let url = item as? URL {
                        self.processSharedFile(sourceUrl: url)
                    } else {
                        self.closeExtension()
                    }
                }
        } else {
            closeExtension()
        }
    }

    private func processSharedFile(sourceUrl: URL) {
        // App Group Yolu (StorageManager'dan alıyoruz, hata yapma şansı yok)
        let destinationUrl = StorageManager.shared.getNewRecordingURL()
        let fileName = destinationUrl.lastPathComponent
        
        do {
            // Güvenlik Kapsamı Erişimi
            let secured = sourceUrl.startAccessingSecurityScopedResource()
            
            // Dosyayı Kopyala
            try FileManager.default.copyItem(at: sourceUrl, to: destinationUrl)
            
            if secured { sourceUrl.stopAccessingSecurityScopedResource() }
            
            // Veritabanına Kaydet
            saveToDatabase(fileName: fileName)
            
        } catch {
            print("❌ Dosya kopyalama hatası: \(error)")
            closeExtension()
        }
    }
    
    private func saveToDatabase(fileName: String) {
        do {
            // SwiftData Kurulumu (Manuel ama Shared Path ile)
            // StorageManager.shared.containerURL bize doğru AppGroup yolunu verir.
            let storeURL = StorageManager.shared.containerURL.appendingPathComponent(
                "MindSift.sqlite"
            )
            let config = ModelConfiguration(url: storeURL, allowsSave: true)
            
            // VoiceNote modeli her iki target'ta da seçili olmalı!
            let container = try ModelContainer(
                for: VoiceNote.self,
                configurations: config
            )
            let context = ModelContext(container)
            
            let newNote = VoiceNote(
                audioFileName: fileName,
                transcription: nil,
                title: "Dışarıdan Gelen Kayıt",
                summary: "Analiz için uygulamayı açın...",
                type: .unclassified,
                isProcessed: false // Ana uygulama açılınca işleyecek
            )
            
            context.insert(newNote)
            try context.save()
            print("✅ Paylaşılan dosya kaydedildi: \(fileName)")
            
            closeExtension()
            
        } catch {
            print("❌ Veritabanı hatası: \(error)")
            closeExtension()
        }
    }
    
    private func closeExtension() {
        DispatchQueue.main.async {
            self.extensionContext?
                .completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
