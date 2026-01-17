//
//  LanguageManager.swift
//  FilamentTracker
//
//  Language management utility
//

import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language {
        didSet {
            applyLanguage(currentLanguage)
        }
    }
    
    private init() {
        // Load saved language preference or default to system
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
        applyLanguage(currentLanguage)
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "AppLanguage")
        UserDefaults.standard.synchronize()
    }
    
    private func applyLanguage(_ language: Language) {
        var languageCode: String?
        
        switch language {
        case .system:
            // Use system language
            languageCode = nil
        case .english:
            languageCode = "en"
        case .chinese:
            languageCode = "zh-Hans"
        }
        
        if let languageCode = languageCode {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        } else {
            // Reset to system language
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        
        // Post notification to reload views
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    var displayName: String {
        switch currentLanguage {
        case .system:
            return String(localized: "home.language.system", bundle: .main)
        case .english:
            return String(localized: "home.language.english", bundle: .main)
        case .chinese:
            return String(localized: "home.language.chinese", bundle: .main)
        }
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
