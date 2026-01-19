//
//  RootInitializer.swift
//  FilamentTracker
//
//  Runs one-time initialization logic when the app first shows ContentView.
//

import SwiftUI
import SwiftData

struct RootInitializer<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .task {
                await seedDefaultMaterialColorsIfNeeded()
            }
    }
    
    /// Seed default material → color mappings on first launch.
    /// This only runs once: if there is already any MaterialColorConfig, it does nothing.
    @MainActor
    private func seedDefaultMaterialColorsIfNeeded() async {
        let descriptor = FetchDescriptor<MaterialColorConfig>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        
        let materials = MaterialColorConfig.defaultMaterials
        let palette = MaterialColorConfig.defaultPalette
        guard !materials.isEmpty, !palette.isEmpty else { return }
        
        for (index, material) in materials.enumerated() {
            let color = palette[index % palette.count]
            let config = MaterialColorConfig(material: material, colorHex: color)
            modelContext.insert(config)
        }
        
        try? modelContext.save()
    }
}

