//
//  Filament.swift
//  FilamentTracker
//
//  Data model for filament spool
//

import Foundation
import SwiftData

@Model
final class Filament {
    @Attribute(.unique) var id: UUID
    var brand: String
    var material: String
    var colorName: String
    var colorHex: String
    var diameter: Double
    var initialWeight: Double
    var remainingWeight: Double
    var emptySpoolWeight: Double?
    var density: Double?
    var minTemp: Int?
    var maxTemp: Int?
    var bedTemp: Int?
    var price: Decimal?
    var purchaseDate: Date
    var isArchived: Bool
    var notes: String?
    
    @Relationship(deleteRule: .cascade, inverse: \UsageLog.filament)
    var logs: [UsageLog] = []
    
    init(
        id: UUID = UUID(),
        brand: String = "",
        material: String = "",
        colorName: String = "",
        colorHex: String = "#CCCCCC",
        diameter: Double = 1.75,
        initialWeight: Double = 1000.0,
        remainingWeight: Double = 1000.0,
        emptySpoolWeight: Double? = nil,
        density: Double? = nil,
        minTemp: Int? = nil,
        maxTemp: Int? = nil,
        bedTemp: Int? = nil,
        price: Decimal? = nil,
        purchaseDate: Date = Date(),
        isArchived: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.brand = brand
        self.material = material
        self.colorName = colorName
        self.colorHex = colorHex
        self.diameter = diameter
        self.initialWeight = initialWeight
        self.remainingWeight = remainingWeight
        self.emptySpoolWeight = emptySpoolWeight
        self.density = density
        self.minTemp = minTemp
        self.maxTemp = maxTemp
        self.bedTemp = bedTemp
        self.price = price
        self.purchaseDate = purchaseDate
        self.isArchived = isArchived
        self.notes = notes
    }
    
    var remainingPercentage: Double {
        guard initialWeight > 0 else { return 0 }
        return (remainingWeight / initialWeight) * 100
    }
    
    var isLowStock: Bool {
        remainingPercentage < 20
    }
    
    var daysSincePurchase: Int {
        Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
    }
}

