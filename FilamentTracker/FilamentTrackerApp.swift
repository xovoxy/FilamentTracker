//
//  FilamentTrackerApp.swift
//  FilamentTracker
//
//  Created on 2024
//

import SwiftUI
import SwiftData

// AppDelegate for orientation control
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct FilamentTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
