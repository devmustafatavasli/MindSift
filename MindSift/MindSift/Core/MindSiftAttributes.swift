//
//  MindSiftAttributes.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import ActivityKit
import SwiftUI

struct MindSiftAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Canlı güncellenecek veriler
        var status: String // "Dinliyor...", "Düşünüyor...", "Kaydedildi"
        var timer: Date    // Kayıt başlangıç zamanı
    }

    // Sabit veriler (Aktivite başladığında bir kere belirlenir)
    var activityName: String
}
