//
//  MindSiftWidgetLiveActivity.swift
//  MindSiftWidget
//
//  Created by Mustafa TAVASLI on 8.12.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct MindSiftWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MindSiftAttributes.self) { context in
            // ------------------------------------------------
            // 1. KİLİT EKRANI (LOCK SCREEN) GÖRÜNÜMÜ
            // ------------------------------------------------
            HStack {
                // Sol: İkon ve Dalga
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .symbolEffect(
                            .variableColor.iterative,
                            options: .repeating
                        )
                }
                
                VStack(alignment: .leading) {
                    Text(context.attributes.activityName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(context.state.status)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Sağ: Süre Sayacı
                Text(context.state.timer, style: .timer)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .fontWeight(.bold)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            // ------------------------------------------------
            // 2. DYNAMIC ISLAND (ADA) GÖRÜNÜMLERİ
            // ------------------------------------------------
            DynamicIsland {
                // A. GENİŞLETİLMİŞ MOD (EXPANDED) - Uzun basınca açılır
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.red)
                        Text("Kayıt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timer, style: .timer)
                        .font(.monospacedDigit(.body)())
                        .foregroundStyle(.yellow)
                        .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Butonlar ve Dalga Formu
                    VStack(spacing: 12) {
                        // Sahte Ses Dalgası Animasyonu
                        HStack(spacing: 4) {
                            ForEach(0..<10) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [.red, .purple],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(
                                        width: 4,
                                        height: CGFloat.random(in: 10...30)
                                    )
                            }
                        }
                        .frame(height: 30)
                        
                        // Aksiyon Butonu (Durdur)
                        Button(intent: StopRecordingIntent()) {
                            Label(
                                "Kaydı Bitir",
                                systemImage: "stop.circle.fill"
                            )
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(
                            .plain
                        ) // Butonun ada içinde parlamasını engeller
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
            } compactLeading: {
                // B. KAPALI MOD (SOL)
                HStack {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                        .symbolEffect(.variableColor, options: .repeating)
                }
                .padding(.leading, 4)
                
            } compactTrailing: {
                // C. KAPALI MOD (SAĞ)
                Text(context.state.timer, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.yellow)
                    .frame(
                        width: 40
                    ) // Genişlik sabitlenmezse titreme yapabilir
                
            } minimal: {
                // D. MİNİMAL MOD (Başka uygulama adayı kullanıyorsa)
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            }
            .keylineTint(Color.red) // Ada çerçeve rengi
        }
    }
}


#Preview(
    "Recording State",
    as: .content,
    using: MindSiftAttributes(activityName: "MindSift Kaydı")
) {
    MindSiftWidgetLiveActivity()
} contentStates: {
    MindSiftAttributes.ContentState(status: "Dinliyor...", timer: Date())
    MindSiftAttributes
        .ContentState(
            status: "İşleniyor...",
            timer: Date().addingTimeInterval(-60)
        )
}
