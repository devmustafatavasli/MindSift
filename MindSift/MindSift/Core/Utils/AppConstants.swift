//
//  AppConstants.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import Foundation

// MARK: Uygulama Sabitleri
// Hard-coded değerler

struct AppConstants {

    struct Texts {
        
        static let appName = "MindSift"
        
        struct Onboarding {
            static let title = "MindSift'e Hoşgeldin"
            static let subtitle = "Düşüncelerini sese dök, yapay zeka onları senin için organize etsin."
            static let feature1Title = "Hızlı Kayıt"
            static let feature1Desc = "Tek dokunuşla kaydet."
            static let feature2Title = "AI Analizi"
            static let feature2Desc = "Özetler, başlıklar ve aksiyonlar."
            static let feature3Title = "Akıllı Takvim"
            static let feature3Desc = "Planların otomatik takvime işlensin."
            static let skipButton = "Şimdilik Geç"
        }
        
        struct Home {
            static let searchPlaceholder = "Notlarda ara..."
            static let emptyTitle = "Zihnin Çok mu Dolu?"
            static let emptySubtitle = "Mikrofona dokun ve aklındakileri boşalt.\nMindSift gerisini halleder."
            static let noResults = "Sonuç bulunamadı."
            static let recordingState = "Kaydediliyor..."
            static let analyzingState = "Süzülüyor..."
            static let idleState = "Düşünceni Kaydet"
        }
        
        struct Detail {
            static let transcriptTitle = "Transkript"
            static let aiSummaryTitle = "AI Özeti"
            static let emailDraftTitle = "E-posta Taslağı"
            static let openMailButton = "Mail Uygulamasında Aç"
            static let audioError = "Ses çözülemedi."
            static let shareSuffix = "\n🤖 MindSift ile oluşturuldu."
        }
        
        struct Settings {
            static let title = "Ayarlar"
            static let sectionGeneral = "Görünüm ve Zaman"
            static let sectionAccount = "Hesap"
            static let sectionData = "Veri"
            static let sectionAbout = "Hakkında"
            static let toggle24Hour = "24 Saat Biçimi"
            static let deleteDataButton = "Tüm Notları Sil"
            static let deleteDataFooter = "Tüm sesli notlarınızı ve analiz geçmişini cihazdan kalıcı olarak siler."
            static let version = "Sürüm"
            static let versionNumber = "1.0.0 (Beta)"
            static let signInButton = "Apple ile Giriş Yap"
            static let signOutButton = "Çıkış Yap"
            static let loggedInStatus = "Oturum Açıldı"
            static let guestStatus = "Giriş yapılmadı"
        }
        
        struct Actions {
            static let delete = "Sil"
            static let cancel = "İptal"
            static let ok = "Tamam"
            static let share = "Paylaş"
            static let done = "Bitti"
        }
        
        struct Errors {
            static let generalError = "Bir hata oluştu."
            static let analysisFailed = "Analiz edilemedi."
            static let mailAppNotFound = "Mail uygulaması bulunamadı. İçerik panoya kopyalandı."
            static let noInternet = "İnternet bağlantısı yok. AI analizi yapılamaz."
            static let deleteConfirmationTitle = "Tüm Veriler Silinecek"
            static let deleteConfirmationMsg = "Bu işlem geri alınamaz. Kaydedilen tüm notlar silinecektir."
        }
    }
    
    // 🖼️ İkon İsimleri (SF Symbols)
    struct Icons {
        static let micFill = "mic.fill"
        static let stopFill = "stop.fill"
        static let waveform = "waveform"
        static let sparkles = "sparkles"
        static let magnifyingGlass = "magnifyingglass"
        static let xmarkCircle = "xmark.circle.fill"
        static let gear = "gearshape.fill"
        static let trash = "trash"
        static let share = "square.and.arrow.up"
        static let play = "play.circle.fill"
        static let pause = "pause.circle.fill"
        static let envelope = "envelope.fill"
        static let arrowUpRight = "arrow.up.right.circle.fill"
        static let textAlignLeft = "text.alignleft"
        static let network = "network" // MindMap
        static let list = "list.bullet"
        static let plus = "plus"
        static let minus = "minus"
        static let location = "location.fill"
        static let calendar = "calendar"
        static let calendarBadgeClock = "calendar.badge.clock"
        static let chevronRight = "chevron.right"
        static let personCropCircle = "person.crop.circle.fill"
        static let personCropCircleCheck = "person.crop.circle.badge.checkmark"
    }
    
    // ⏱️ Animasyon ve Zamanlama
    struct Animation {
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.6
        static let blobDuration: Double = 1.5
    }
}
