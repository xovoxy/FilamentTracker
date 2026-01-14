//
//  UsageLog.swift
//  FilamentTracker
//
//  Data model for usage tracking
//

import Foundation
import SwiftData

enum UsageType: String, Codable, CaseIterable {
    case print = "print"
    case failedPrint = "failed_print"
    case calibration = "calibration"
    case manualAdjustment = "manual_adjustment"
    
    var displayName: String {
        switch self {
        case .print: return "Print"
        case .failedPrint: return "Failed Print"
        case .calibration: return "Calibration"
        case .manualAdjustment: return "Manual Adjustment"
        }
    }
}

@Model
final class UsageLog {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var date: Date
    var note: String?
    var type: String
    
    var filament: Filament?
    
    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date = Date(),
        note: String? = nil,
        type: UsageType = .print,
        filament: Filament? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.type = type.rawValue
        self.filament = filament
    }
    
    var usageType: UsageType {
        get {
            UsageType(rawValue: type) ?? .print
        }
        set {
            type = newValue.rawValue
        }
    }
}
