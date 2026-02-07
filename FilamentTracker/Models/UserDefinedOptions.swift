//
//  UserDefinedOptions.swift
//  FilamentTracker
//
//  SwiftData models for user-defined brands and material types
//

import Foundation
import SwiftData

@Model
final class CustomBrand {
    @Attribute(.unique) var name: String
    var createdAt: Date

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
final class CustomMaterialType {
    @Attribute(.unique) var name: String
    var createdAt: Date

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}
