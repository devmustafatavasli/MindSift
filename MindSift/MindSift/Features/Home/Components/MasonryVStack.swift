//
//  MasonryVStack.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 8.12.2025.
//


//
//  MasonryVStack.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 8.12.2025.
//

import SwiftUI

struct MasonryVStack<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let content: (VoiceNote) -> Content
    var items: [VoiceNote]
    
    init(columns: Int = 2, spacing: CGFloat = 12, items: [VoiceNote], @ViewBuilder content: @escaping (VoiceNote) -> Content) {
        self.columns = columns
        self.spacing = spacing
        self.items = items
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    // Matematiksel Dağıtım: Index % KolonSayısı == KolonNo
                    // Örn: 0, 2, 4. notlar -> 1. Sütun
                    //      1, 3, 5. notlar -> 2. Sütun
                    ForEach(items.filter { getColumnIndex(for: $0) == columnIndex }) { item in
                        content(item)
                    }
                }
            }
        }
    }
    
    // Yardımcı: Bir notun hangi sütuna düşeceğini hesaplar
    private func getColumnIndex(for item: VoiceNote) -> Int {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return 0 }
        return index % columns
    }
}