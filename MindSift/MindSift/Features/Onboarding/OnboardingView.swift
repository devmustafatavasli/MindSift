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
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            DesignSystem.Gradients.primaryAction
                .opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: AppConstants.Icons.waveform)
                    .font(.system(size: 100))
                    .foregroundStyle(DesignSystem.Gradients.primaryAction)
                    .shadow(radius: 10)
                
                VStack(spacing: 12) {
                    Text(AppConstants.Texts.Onboarding.title)
                        .font(DesignSystem.Typography.titleLarge())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Text(AppConstants.Texts.Onboarding.subtitle)
                        .font(DesignSystem.Typography.body())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: AppConstants.Icons.micFill,
                        title: AppConstants.Texts.Onboarding.feature1Title,
                        desc: AppConstants.Texts.Onboarding.feature1Desc
                    )
                    FeatureRow(
                        icon: AppConstants.Icons.sparkles,
                        title: AppConstants.Texts.Onboarding.feature2Title,
                        desc: AppConstants.Texts.Onboarding.feature2Desc
                    )
                    FeatureRow(
                        icon: AppConstants.Icons.calendar,
                        title: AppConstants.Texts.Onboarding.feature3Title,
                        desc: AppConstants.Texts.Onboarding.feature3Desc
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            authManager.handleSignIn(result: result)
                            if authManager.isSignedIn { completeOnboarding() }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    Button {
                        completeOnboarding()
                    } label: {
                        Text(AppConstants.Texts.Onboarding.skipButton)
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation { hasSeenOnboarding = true }
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
