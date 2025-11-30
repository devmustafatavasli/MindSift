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
        // Dinleme - Düşünme - Kaydetme Aşamaları
        var status: String
        // Kayıt Zaman Sayacı
        var timer: Date
    }
    // Aktivitenin Adlandırması
    var activityName: String
}
