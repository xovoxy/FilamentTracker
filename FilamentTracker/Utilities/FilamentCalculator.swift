//
//  FilamentCalculator.swift
//  FilamentTracker
//
//  Utility functions for weight and unit conversions
//

import Foundation

struct FilamentCalculator {
    // Material density constants (g/cm³)
    static let densityPLA: Double = 1.24
    static let densityPETG: Double = 1.27
    static let densityABS: Double = 1.04
    static let densityTPU: Double = 1.20
    
    static func density(for material: String) -> Double {
        let materialUpper = material.uppercased()
        switch materialUpper {
        case "PLA":
            return densityPLA
        case "PETG":
            return densityPETG
        case "ABS":
            return densityABS
        case "TPU":
            return densityTPU
        default:
            return densityPLA // Default to PLA
        }
    }
    
    /// Convert length (meters) to weight (grams)
    /// Formula: Weight (g) = Length (cm) * Area (cm²) * Density (g/cm³)
    static func lengthToWeight(lengthMeters: Double, diameter: Double, density: Double) -> Double {
        let lengthCm = lengthMeters * 100
        let radiusCm = (diameter / 2) / 10 // Convert mm to cm
        let areaCm2 = Double.pi * radiusCm * radiusCm
        return lengthCm * areaCm2 * density
    }
    
    /// Convert weight (grams) to length (meters)
    static func weightToLength(weightGrams: Double, diameter: Double, density: Double) -> Double {
        let radiusCm = (diameter / 2) / 10
        let areaCm2 = Double.pi * radiusCm * radiusCm
        let lengthCm = weightGrams / (areaCm2 * density)
        return lengthCm / 100 // Convert to meters
    }
    
    /// Calculate net weight from gross weight
    static func netWeight(grossWeight: Double, emptySpoolWeight: Double) -> Double {
        return max(0, grossWeight - emptySpoolWeight)
    }
    
    /// Calculate used amount from previous and current gross weights
    static func calculateUsedAmount(
        previousRemaining: Double,
        currentGrossWeight: Double,
        emptySpoolWeight: Double
    ) -> Double {
        let newNetWeight = netWeight(grossWeight: currentGrossWeight, emptySpoolWeight: emptySpoolWeight)
        return max(0, previousRemaining - newNetWeight)
    }
}
