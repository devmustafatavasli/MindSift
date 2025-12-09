//
//  MindSiftAttributes.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 8.12.2025.
//

import ActivityKit
import Foundation

struct MindSiftAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Değişken veriler (Süre, Durum)
        var status: String
        var timer: Date // Kayıt başlangıç zamanı (Sayacı buradan hesaplar)
    }

    // Sabit veriler (Başlık vb.)
    var activityName: String
}
