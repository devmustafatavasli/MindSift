//
//  SettingsView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 1. DEĞİŞİKLİK: @StateObject yerine @State
    // iOS 17+ Observation framework'ü
    @State private var viewModel = SettingsViewModel()
    
    @AppStorage("is24HourTime") private var is24HourTime = true
    
    var body: some View {
        // 2. DEĞİŞİKLİK: Binding işlemi için @Bindable (Alert için gerekli)
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            Form {
                // 1. GENEL
                Section(
                    header: Text(AppConstants.Texts.Settings.sectionGeneral)
                ) {
                    Toggle(
                        AppConstants.Texts.Settings.toggle24Hour,
                        isOn: $is24HourTime
                    )
                    .tint(DesignSystem.Colors.primaryBlue)
                }
                
                // 2. HESAP
                Section(
                    header: Text(AppConstants.Texts.Settings.sectionAccount)
                ) {
                    HStack(spacing: 12) {
                        Image(
                            systemName: viewModel.authManager.isSignedIn ? AppConstants.Icons.personCropCircleCheck : AppConstants.Icons.personCropCircle
                        )
                        .font(.largeTitle)
                        .foregroundStyle(
                            viewModel.authManager.isSignedIn ? DesignSystem.Colors.success : .gray
                        )
                        .symbolEffect(
                            .bounce,
                            value: viewModel.authManager.isSignedIn
                        )
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.authManager.userName)
                                .font(DesignSystem.Typography.headline())
                            Text(
                                viewModel.authManager.isSignedIn ? AppConstants.Texts.Settings.loggedInStatus : AppConstants.Texts.Settings.guestStatus
                            )
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if viewModel.authManager.isSignedIn {
                        Button(role: .destructive) {
                            viewModel.authManager.signOut()
                        } label: {
                            Text(AppConstants.Texts.Settings.signOutButton)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                viewModel.authManager
                                    .handleSignIn(result: result)
                            }
                        )
                        .frame(height: 44)
                        .signInWithAppleButtonStyle(.black)
                    }
                }
                
                // 3. VERİ YÖNETİMİ
                Section {
                    Button(role: .destructive) {
                        viewModel.showDeleteAlert = true
                    } label: {
                        Label(
                            AppConstants.Texts.Settings.deleteDataButton,
                            systemImage: AppConstants.Icons.trash
                        )
                    }
                } header: {
                    Text(AppConstants.Texts.Settings.sectionData)
                } footer: {
                    Text(AppConstants.Texts.Settings.deleteDataFooter)
                }
                
                // 4. HAKKINDA
                Section {
                    HStack {
                        Text(AppConstants.Texts.Settings.version)
                        Spacer()
                        Text(AppConstants.Texts.Settings.versionNumber)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                } header: {
                    Text(AppConstants.Texts.Settings.sectionAbout)
                }
            }
            .navigationTitle(AppConstants.Texts.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppConstants.Texts.Actions.done) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert(
                AppConstants.Texts.Errors.deleteConfirmationTitle,
                isPresented: $viewModel.showDeleteAlert
            ) {
                Button(AppConstants.Texts.Actions.cancel, role: .cancel) { }
                Button(AppConstants.Texts.Actions.delete, role: .destructive) {
                    viewModel.deleteAllData(context: modelContext)
                }
            } message: {
                Text(AppConstants.Texts.Errors.deleteConfirmationMsg)
            }
        }
    }
}
