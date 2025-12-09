import Foundation

class StorageManager {
    
    // Singleton: Her yerden tek erişim
    static let shared = StorageManager()
    
    // ⚠️ Kendi App Group ID'n ile değiştirmeyi unutma!
    private let appGroupIdentifier = "group.com.devmustafatavasli.MindSift"
    
    private init() {}
    
    // MARK: - Temel Yollar
    
    /// App Group ortak klasörünün yolu. Bulunamazsa standart Documents döner.
    var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return url
        }
        // Fallback: Simülatör hatası veya yetki sorunu olursa uygulama çökmesin
        print("⚠️ App Group bulunamadı, Documents kullanılıyor.")
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Dosya İşlemleri
    
    /// Yeni kayıt yapılacak dosyanın tam yolunu verir.
    func getNewRecordingURL() -> URL {
        let fileName = "voice_note_\(Date().timeIntervalSince1970).m4a"
        return containerURL.appendingPathComponent(fileName)
    }
    
    /// Dosya isminden tam yolu bulur (Okuma işlemleri için).
    func getFileURL(fileName: String) -> URL {
        let groupURL = containerURL.appendingPathComponent(fileName)
        
        // 1. Önce App Group'a bak (Öncelikli yer)
        if FileManager.default.fileExists(atPath: groupURL.path) {
            return groupURL
        }
        
        // 2. Orada yoksa Documents'a bak (Eski versiyondan kalan dosyalar için geriye dönük uyumluluk)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            return documentsURL
        }
        
        // 3. Hiçbiri yoksa varsayılan olarak Group yolunu dön (Hata yönetimi çağıran yerde yapılır)
        return groupURL
    }
    
    /// Dosyayı fiziksel olarak siler.
    func deleteFile(fileName: String) {
        let url = getFileURL(fileName: fileName)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("🗑️ Dosya silindi: \(fileName)")
            }
        } catch {
            print("❌ Dosya silme hatası: \(error.localizedDescription)")
        }
    }
}
