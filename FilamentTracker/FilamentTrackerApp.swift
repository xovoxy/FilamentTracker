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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self])
    }
}
