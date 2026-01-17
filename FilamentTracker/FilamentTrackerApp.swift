//
//  FilamentTrackerApp.swift
//  FilamentTracker
//
//  Created on 2024
//

import SwiftUI
import SwiftData

@main
struct FilamentTrackerApp: App {
    init() {
        // Initialize language manager on app launch
        _ = LanguageManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self])
    }
}
