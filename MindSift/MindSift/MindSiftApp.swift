import SwiftUI
import SwiftData

@main
struct MindSiftApp: App {
    // Onboarding Durumu
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    // DataController başlatıldığı an veritabanı kurulur.
    let dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        // Konteyneri buradan tüm uygulamaya dağıtıyoruz.
        .modelContainer(dataController.container)
    }
}
