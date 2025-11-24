//
//  CalendarManager.swift
//  MindSift
//
//  Created by Mustafa TAVASLI on 24.11.2025.
//

import Foundation
import EventKit
import Combine

// MARK: - Calendar Manager
// Görevi: Apple Takvimi ile konuşmak ve etkinlik eklemek.

class CalendarManager: ObservableObject {
    
    private let eventStore = EKEventStore()
    
    @Published var hasPermission: Bool = false
    @Published var errorMessage: String?
    
    init() {
        checkPermissions()
    }
    
    // 1. İzin İsteme
    func checkPermissions() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            self.hasPermission = true
        case .notDetermined:
            requestAccess()
        case .denied, .restricted:
            self.hasPermission = false
            self.errorMessage = "Takvim erişim izni reddedildi."
        @unknown default:
            break
        }
    }
    
    private func requestAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            // iOS 17 öncesi için
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        }
    }
    
    // 2. Etkinlik Ekleme Fonksiyonu
    func addEvent(title: String, date: Date, notes: String?) {
        guard hasPermission else {
            self.errorMessage = "Takvim izni yok."
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        // Varsayılan olarak etkinlik 1 saat sürsün
        event.endDate = date.addingTimeInterval(3600)
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Takvime eklendi: \(title) - \(date)")
        } catch {
            print("❌ Takvim Hatası: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = "Etkinlik takvime eklenemedi."
            }
        }
    }
}
