//
//  NetworkManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import Network
import SwiftUI
import Combine

// MARK: - Network Manager
// Uygulamanın internet bağlantı durumunu takip eder.

class NetworkManager: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkManager")
    
    // UI tarafından dinlenen bağlantı durumu
    @Published var isConnected: Bool = true
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                // .satisfied = İnternet var
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
