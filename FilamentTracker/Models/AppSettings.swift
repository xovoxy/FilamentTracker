//
//  AppSettings.swift
//  FilamentTracker
//
//  User preferences and settings
//

import Foundation
import SwiftData

enum Language: String, Codable, CaseIterable {
    case system = "system"
    case english = "en"
    case chinese = "zh_Hans"
}

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultDiameter: Double
    var lowStockThreshold: Double
    var currency: String
    var language: String
    
    init(
        id: UUID = UUID(),
        defaultDiameter: Double = 1.75,
        lowStockThreshold: Double = 20.0,
        currency: String = "$",
        language: Language = .system
    ) {
        self.id = id
        self.defaultDiameter = defaultDiameter
        self.lowStockThreshold = lowStockThreshold
        self.currency = currency
        self.language = language.rawValue
    }
    
    var languageSetting: Language {
        get {
            Language(rawValue: language) ?? .system
        }
        set {
            language = newValue.rawValue
        }
    }
}
