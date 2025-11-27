//
//  SettingsView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 25.11.2025.
//


import SwiftUI
import SwiftData
import AuthenticationServices // <-- EKLE

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Auth Manager'ı buraya bağlıyoruz
    @StateObject private var authManager = AuthenticationManager()
    
    @AppStorage("is24HourTime") private var is24HourTime = true
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. GENEL AYARLAR
                Section {
                    Toggle("24 Saat Biçimi", isOn: $is24HourTime)
                        .tint(.blue)
                } header: {
                    Text("Görünüm ve Zaman")
                }
                
                // 2. HESAP (SIWA ENTEGRE EDİLDİ)
                Section {
                    HStack(spacing: 12) {
                        Image(
                            systemName: authManager.isSignedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle.fill"
                        )
                        .font(.largeTitle)
                        .foregroundStyle(
                            authManager.isSignedIn ? .green : .gray
                        )
                        .symbolEffect(.bounce, value: authManager.isSignedIn)
                        
                        VStack(alignment: .leading) {
                            Text(authManager.userName)
                                .font(.headline)
                            Text(
                                authManager.isSignedIn ? "Oturum Açıldı" : "Giriş yapılmadı"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if authManager.isSignedIn {
                        // ÇIKIŞ BUTONU
                        Button(role: .destructive) {
                            authManager.signOut()
                        } label: {
                            Text("Çıkış Yap")
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        // GİRİŞ BUTONU (Apple Native Button)
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                authManager.handleSignIn(result: result)
                            }
                        )
                        .frame(height: 44)
                        .signInWithAppleButtonStyle(.black) // Dark mode uyumlu
                    }
                } header: {
                    Text("Hesap")
                }
                
                // 3. VERİ YÖNETİMİ
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Tüm Notları Sil", systemImage: "trash")
                    }
                } header: {
                    Text("Veri")
                } footer: {
                    Text(
                        "Tüm sesli notlarınızı ve analiz geçmişini cihazdan kalıcı olarak siler."
                    )
                }
                
                // 4. HAKKINDA
                Section {
                    HStack {
                        Text("Sürüm")
                        Spacer()
                        Text("1.0.0 (Beta)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Hakkında")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bitti") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Tüm Veriler Silinecek", isPresented: $showDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text(
                    "Bu işlem geri alınamaz. Kaydedilen tüm notlar silinecektir."
                )
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: VoiceNote.self)
            print("🗑️ Tüm veriler temizlendi.")
        } catch {
            print("Silme hatası: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
