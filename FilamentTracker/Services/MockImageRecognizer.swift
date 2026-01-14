//
//  MockImageRecognizer.swift
//  FilamentTracker
//
//  Mock service to simulate AI image recognition for filament labels
//

import Foundation
import UIKit

struct RecognizedFilamentData {
    var brand: String?
    var material: String?
    var colorName: String?
    var colorHex: String?
    var weight: String?
    var diameter: Double?
    var minTemp: String?
    var maxTemp: String?
    var bedTemp: String?
}

class MockImageRecognizer {
    static let shared = MockImageRecognizer()
    
    private init() {}
    
    func analyze(_ image: UIImage) async throws -> RecognizedFilamentData {
        // Simulate network/processing delay
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000) // 2 seconds delay
        
        // Return mock data randomly to simulate different results
        let mockScenarios = [
            RecognizedFilamentData(
                brand: "Bambu Lab",
                material: "PLA",
                colorName: "Matte Charcoal",
                colorHex: "#333333",
                weight: "1000",
                diameter: 1.75,
                minTemp: "190",
                maxTemp: "230",
                bedTemp: "55"
            ),
            RecognizedFilamentData(
                brand: "Polymaker",
                material: "PETG",
                colorName: "Teal Blue",
                colorHex: "#008080",
                weight: "1000",
                diameter: 1.75,
                minTemp: "230",
                maxTemp: "250",
                bedTemp: "70"
            ),
            RecognizedFilamentData(
                brand: "Sunlu",
                material: "PLA+",
                colorName: "Silk Gold",
                colorHex: "#FFD700",
                weight: "1000",
                diameter: 1.75,
                minTemp: "200",
                maxTemp: "230",
                bedTemp: "60"
            )
        ]
        
        return mockScenarios.randomElement()!
    }
}
