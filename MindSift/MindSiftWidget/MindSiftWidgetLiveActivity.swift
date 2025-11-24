//
//  MindSiftWidgetLiveActivity.swift
//  MindSiftWidget
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MindSiftWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MindSiftAttributes.self) { context in
            // 1. KİLİT EKRANI (Lock Screen)
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse, isActive: true)
                
                VStack(alignment: .leading) {
                    Text("MindSift")
                        .font(.headline)
                    Text(context.state.status)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Kronometre (timer stili otomatik sayar)
                Text(context.state.timer, style: .timer)
                    .font(.monospacedDigit(.body)())
                    .foregroundStyle(.blue)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))

        } dynamicIsland: { context in
            // 2. DYNAMIC ISLAND
            DynamicIsland {
                // A. Genişletilmiş (Basılı tutunca)
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.red)
                        Text(context.state.status)
                            .font(.caption)
                            .bold()
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timer, style: .timer)
                        .font(.monospacedDigit(.body)())
                        .foregroundStyle(.blue)
                        .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Ses dalgası animasyonu
                    HStack(spacing: 4) {
                        ForEach(0..<8) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.red.opacity(0.6))
                                .frame(width: 4, height: 20)
                        }
                    }
                    .frame(height: 30)
                }
                
            } compactLeading: {
                // B. Küçük Sol İkon
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
                    .padding(.leading, 4)
                
            } compactTrailing: {
                // C. Küçük Sağ Sayaç
                Text(context.state.timer, style: .timer)
                    .font(.monospacedDigit(.caption)())
                    .foregroundStyle(.blue)
                    .frame(width: 40)
                
            } minimal: {
                // D. Minimal Görünüm
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}
