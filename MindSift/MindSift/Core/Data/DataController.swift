import SwiftData
import Foundation

@MainActor
class DataController {
    // Tüm uygulama buradan erişecek (Singleton)
    static let shared = DataController()
    
    // Testler ve Önizlemeler için geçici veri tutan versiyon
    static let preview: DataController = {
        let controller = DataController(inMemory: true)
        // Buraya istersen fake veri ekleyebilirsin
        return controller
    }()
    
    let container: ModelContainer
    
    // Başlatıcı (Initializer)
    init(inMemory: Bool = false) {
        // 1. Şema Tanımı (Tablolar)
        let schema = Schema([
            VoiceNote.self,
        ])
        
        // 2. Konfigürasyon Ayarları
        let modelConfiguration: ModelConfiguration
        
        if inMemory {
            // Önizleme ve Testler için RAM'de çalış (Diske yazma)
            modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            // Gerçek Uygulama için App Group kullan
            let appGroupIdentifier = "group.com.devmustafatavasli.MindSift"
            
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            ) {
                let storeURL = containerURL.appendingPathComponent(
                    "MindSift.sqlite"
                )
                modelConfiguration = ModelConfiguration(
                    url: storeURL,
                    allowsSave: true
                )
                print("📂 Veritabanı Yolu: \(storeURL.path)")
            } else {
                print("⚠️ App Group bulunamadı, standart sandbox kullanılıyor.")
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
            }
        }
        
        // 3. Konteyneri Oluştur
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Veritabanı başlatılamadı: \(error)")
        }
    }
}
