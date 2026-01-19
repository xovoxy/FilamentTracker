//
//  MaterialColorConfig.swift
//  FilamentTracker
//
//  Stores a mapping between filament material type and chart color.
//

import Foundation
import SwiftData

@Model
final class MaterialColorConfig {
    @Attribute(.unique) var material: String
    var colorHex: String
    
    init(material: String, colorHex: String) {
        self.material = material
        self.colorHex = colorHex
    }
    
    /// Default color palette used when assigning colors for new materials.
    /// Colors are chosen to be visually distinct and match the existing design.
    static let defaultPalette: [String] = [
        "#7FD4B0", // green
        "#B88A5A", // brown
        "#8BC5D9", // blue
        "#8A7BC4", // purple
        "#F6C85F", // yellow
        "#FF6F61", // coral
        "#6B9B7A", // dark green
        "#C4A574", // tan
        "#F28E2B", // orange
        "#A0CBE8"  // light blue
    ]
    
    /// Default material types used by the app (matches AddMaterialView.materials).
    static let defaultMaterials: [String] = [
        "PLA", "PLA+",
        "ABS",
        "PETG",
        "TPU",
        "ASA",
        "PA",
        "PC",
        "PVA",
        "HIPS",
        "Wood",
        "Carbon",
        "Silk",
        "Matte"
    ]
}

