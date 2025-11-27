//
//  OnboardingView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 27.11.2025.
//


import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthenticationManager()
    
    // Kullanıcının onboarding'i bitirip bitirmediğini takip eder
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            // Arka Plan
            DesignSystem.primaryGradient
                .opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // İkon ve Başlık
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(DesignSystem.primaryGradient)
                    .shadow(radius: 10)
                
                VStack(spacing: 12) {
                    Text("MindSift'e Hoşgeldin")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(
                        "Düşüncelerini sese dök, yapay zeka onları senin için organize etsin."
                    )
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Özellik Listesi
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "mic.fill",
                        title: "Hızlı Kayıt",
                        desc: "Tek dokunuşla kaydet."
                    )
                    FeatureRow(
                        icon: "sparkles",
                        title: "AI Analizi",
                        desc: "Özetler, başlıklar ve aksiyonlar."
                    )
                    FeatureRow(
                        icon: "calendar",
                        title: "Akıllı Takvim",
                        desc: "Planların otomatik takvime işlensin."
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // AKSİYON BUTONLARI
                VStack(spacing: 16) {
                    // Apple ile Giriş Yap
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            authManager.handleSignIn(result: result)
                            if authManager.isSignedIn {
                                completeOnboarding()
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    // Misafir Olarak Devam Et
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Şimdilik Geç")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasSeenOnboarding = true
        }
    }
}

// Yardımcı Görünüm: Özellik Satırı
struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
