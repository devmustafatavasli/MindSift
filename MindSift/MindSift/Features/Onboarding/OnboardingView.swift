//
//  OnboardingView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 27.11.2025.
//

import SwiftUI
import AuthenticationServices

// Onboarding Veri Modeli
struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var authManager = AuthenticationManager()
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    // Sayfa Kontrolü
    @State private var currentPage = 0
    
    // Onboarding İçeriği (Hikaye Akışı)
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Düşüncelerini Yakala",
            description: "Aklına geleni konuş, MindSift senin için kaydetsin ve düzenlesin.",
            iconName: "waveform.circle.fill", // AppConstants.Icons.waveform yerine görsel zenginlik için
            color: .blue
        ),
        OnboardingPage(
            title: "Yapay Zeka Analizi",
            description: "Gemini AI notlarını özetler, kategorize eder ve senin için aksiyon planı çıkarır.",
            iconName: "sparkles",
            color: .purple
        ),
        OnboardingPage(
            title: "Harekete Geç",
            description: "Toplantı notlarını takvime, fikirlerini e-postaya tek dokunuşla dönüştür.",
            iconName: "calendar.badge.clock",
            color: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Arka Plan
            MeshBackground()
                .ignoresSafeArea()
                .opacity(0.3)
            
            VStack {
                // 1. KAYDIRILABİLİR ALAN (TabView)
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            isCurrentPage: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(
                    .page(indexDisplayMode: .never)
                ) // Noktaları biz yapacağız
                .animation(.easeInOut, value: currentPage)
                
                // 2. ALT KONTROL ALANI
                VStack(spacing: 20) {
                    // Sayfa İndikatörü (Noktalar)
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    currentPage == index ? DesignSystem.Colors.textPrimary : Color.gray
                                        .opacity(0.3)
                                )
                                .frame(
                                    width: currentPage == index ? 20 : 8,
                                    height: 8
                                )
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Butonlar (Dinamik Değişim)
                    if currentPage == pages.count - 1 {
                        // SON SAYFA: Giriş Butonu
                        VStack(spacing: 16) {
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [
                                        .fullName,
                                        .email
                                    ]
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
                            .shadow(
                                color: .black.opacity(0.1),
                                radius: 5,
                                x: 0,
                                y: 5
                            )
                            .transition(.opacity.combined(with: .scale))
                            
                            Button {
                                completeOnboarding()
                            } label: {
                                Text("Şimdilik Geç")
                                    .font(DesignSystem.Typography.subheadline())
                                    .foregroundStyle(
                                        DesignSystem.Colors.textSecondary
                                    )
                            }
                        }
                    } else {
                        // ARA SAYFALAR: İlerle Butonu
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Devam Et")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(DesignSystem.Colors.primaryBlue)
                                .cornerRadius(12)
                                .shadow(
                                    color: DesignSystem.Colors.primaryBlue
                                        .opacity(0.3),
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .transition(.opacity)
    }
    
    private func completeOnboarding() {
        withAnimation { hasSeenOnboarding = true }
    }
}

// Tekil Sayfa Tasarımı
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isCurrentPage: Bool // Animasyon tetikleyici
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // İkon (iOS 17 Symbol Effect ile Canlılık)
            Image(systemName: page.iconName)
                .font(.system(size: 80))
                .foregroundStyle(page.color.gradient)
                .padding(40)
                .background(
                    Circle()
                        .fill(page.color.opacity(0.1))
                        .frame(width: 200, height: 200)
                )
                .symbolEffect(
                    .bounce,
                    value: isCurrentPage
                ) // Her sayfaya gelince zıplar
                .shadow(color: page.color.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
