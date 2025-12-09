//
//  AuthenticationManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 27.11.2025.
//

import Foundation
import AuthenticationServices
import Observation // 👈 YENİ

@Observable // 👈 ARTIK BU VAR
class AuthenticationManager: NSObject {
    
    var isSignedIn: Bool = false
    var userIdentifier: String?
    var userName: String = "Misafir"
    
    override init() {
        super.init()
        checkLoginStatus()
    }
    
    // Giriş Durumunu Kontrol Et
    func checkLoginStatus() {
        if let userId = UserDefaults.standard.string(forKey: "userIdentifier") {
            self.userIdentifier = userId
            self.isSignedIn = true
            
            if let name = UserDefaults.standard.string(forKey: "userName") {
                self.userName = name
            }
            
            checkAppleIDCredentialState(userID: userId)
        }
    }
    
    // Giriş Başarılı Olduğunda Çağrılır
    func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                
                if let nameComponents = appleIDCredential.fullName,
                   let givenName = nameComponents.givenName {
                    let name = givenName + " " + (
                        nameComponents.familyName ?? ""
                    )
                    self.userName = name
                    UserDefaults.standard.set(name, forKey: "userName")
                }
                
                self.userIdentifier = userId
                self.isSignedIn = true
                
                UserDefaults.standard.set(userId, forKey: "userIdentifier")
                print("✅ Giriş Başarılı: \(userId)")
            }
        case .failure(let error):
            print("❌ Giriş Hatası: \(error.localizedDescription)")
        }
    }
    
    // Çıkış Yap
    func signOut() {
        self.isSignedIn = false
        self.userIdentifier = nil
        self.userName = "Misafir"
        
        UserDefaults.standard.removeObject(forKey: "userIdentifier")
        UserDefaults.standard.removeObject(forKey: "userName")
        print("🚪 Çıkış yapıldı.")
    }
    
    // Apple ID Durumunu Kontrol Et
    private func checkAppleIDCredentialState(userID: String) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider
            .getCredentialState(forUserID: userID) { (credentialState, error) in
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        print("✅ Apple ID Oturumu Geçerli")
                    case .revoked, .notFound:
                        print("⚠️ Oturum Geçersiz, Çıkış Yapılıyor")
                        self.signOut()
                    default:
                        break
                    }
                }
            }
    }
}
