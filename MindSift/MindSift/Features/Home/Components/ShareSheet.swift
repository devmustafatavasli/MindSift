//
//  ShareSheet.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import SwiftUI
import UIKit

// MARK: - Share Sheet Component
// iOS'in yerel paylaşım menüsünü (UIActivityViewController) SwiftUI içinde kullanmak için sarmalayıcı.

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
