//
//  HomeView.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//


import SwiftUI
import SwiftData

struct HomeView: View {
    // 1. Veritabanı Bağlantısı (Context)
    @Environment(\.modelContext) private var modelContext
    
    // 2. Verileri Çekme (Query)
    // Kayıtları en yeniden en eskiye doğru sıralar
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]
    
    // 3. Ses Yöneticisi
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka Plan Rengi
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // Kayıt Listesi (Varsa)
                    if notes.isEmpty {
                        emptyStateView
                    } else {
                        notesListView
                    }
                    
                    Spacer()
                    
                    // Kayıt Butonu Alanı
                    recordingSection
                }
            }
            .navigationTitle("MindSift")
        }
        // 4. Kayıt bittiğinde veritabanına kaydetme mantığı
        .onChange(of: audioManager.audioURL) { oldValue, newURL in
            if let url = newURL {
                saveNote(url: url)
            }
        }
        // Hata mesajı gösterimi
        .alert("Hata", isPresented: .constant(audioManager.errorMessage != nil)) {
            Button("Tamam", role: .cancel) { audioManager.errorMessage = nil }
        } message: {
            Text(audioManager.errorMessage ?? "")
        }
    }
    
    // MARK: - Alt Görünümler (Components)
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "mic.circle")
                .font(.system(size: 80))
                .foregroundStyle(.gray.opacity(0.5))
            Text("Henüz bir not yok.\nKaydetmek için butona bas.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            Spacer()
        }
    }
    
    private var notesListView: some View {
        List {
            ForEach(notes) { note in
                HStack {
                    Image(systemName: note.type.iconName)
                        .foregroundStyle(.blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading) {
                        Text(note.title ?? "İsimsiz Kayıt")
                            .font(.headline)
                        Text(note.createdAt.formatted(date: .numeric, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    if note.isProcessed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .onDelete(perform: deleteNotes)
        }
        .scrollContentBackground(.hidden) // Listenin gri arka planını kaldırır
    }
    
    private var recordingSection: some View {
        VStack {
            if audioManager.isRecording {
                Text("Dinliyorum...")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }
            
            Button {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                } else {
                    audioManager.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(audioManager.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                    
                    Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
            // Kayıt sırasındaki animasyon
            .scaleEffect(audioManager.isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: audioManager.isRecording)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Mantık Fonksiyonları
    
    private func saveNote(url: URL) {
        // Yeni bir not nesnesi oluştur
        // Not: Burada 'audioFileName' olarak sadece dosya adını alıyoruz.
        let newNote = VoiceNote(audioFileName: url.lastPathComponent)
        
        // Veritabanına ekle
        modelContext.insert(newNote)
        
        print("✅ Not veritabanına kaydedildi: \(newNote.id)")
    }
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(notes[index])
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: VoiceNote.self, inMemory: true)
}