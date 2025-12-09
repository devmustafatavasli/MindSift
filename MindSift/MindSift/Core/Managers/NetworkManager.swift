//
//  NetworkManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 2.12.2025.
//

import Network
import SwiftUI
import Observation

@Observable
class NetworkManager {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkManager")
    
    var isConnected: Bool = true
    var onStatusChange: ((Bool) -> Void)?
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let connected = path.status == .satisfied
                self?.isConnected = connected
                
                // Durum değiştiğinde aboneye haber ver
                self?.onStatusChange?(connected)
            }
        }
        monitor.start(queue: queue)
    }
}
