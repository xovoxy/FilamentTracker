//
//  AddMaterialView.swift
//  FilamentTracker
//
//  Form for adding/editing filament material
//

import SwiftUI
import SwiftData

struct AddMaterialView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var brand: String = ""
    @State private var material: String = "PLA"
    @State private var colorName: String = ""
    @State private var colorHex: String = "#CCCCCC"
    @State private var diameter: Double = 1.75
    @State private var initialWeight: String = ""
    @State private var remainingWeight: String = ""
    @State private var emptySpoolWeight: String = ""
    @State private var price: String = ""
    @State private var minTemp: String = ""
    @State private var maxTemp: String = ""
    @State private var bedTemp: String = ""
    
    let filament: Filament?
    let materials = ["PLA", "PETG", "ABS", "TPU", "Other"]
    let presetColors: [(String, String)] = [
        ("Black", "#000000"),
        ("White", "#FFFFFF"),
        ("Red", "#FF0000"),
        ("Blue", "#0000FF"),
        ("Green", "#00FF00"),
        ("Yellow", "#FFFF00"),
        ("Orange", "#FFA500"),
        ("Purple", "#800080"),
        ("Pink", "#FFC0CB"),
        ("Teal", "#008080")
    ]
    
    init(filament: Filament? = nil) {
        self.filament = filament
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Material Name
                    HStack {
                        Image(systemName: "spool")
                            .foregroundColor(.teal)
                            .frame(width: 30)
                        TextField("Material Name", text: $brand)
                    }
                    
                    // Weight
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.teal)
                            .frame(width: 30)
                        TextField("Weight (g)", text: $initialWeight)
                            .keyboardType(.decimalPad)
                    }
                    
                    // Cost
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.teal)
                            .frame(width: 30)
                        TextField("Cost", text: $price)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Add Material")
                }
                
                Section {
                    Picker("Material Type", selection: $material) {
                        ForEach(materials, id: \.self) { mat in
                            Text(mat).tag(mat)
                        }
                    }
                    
                    TextField("Color Name", text: $colorName)
                    
                    // Color picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(presetColors, id: \.0) { color in
                                ColorButton(
                                    name: color.0,
                                    hex: color.1,
                                    isSelected: colorHex == color.1
                                ) {
                                    colorHex = color.1
                                    if colorName.isEmpty {
                                        colorName = color.0
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Details")
                }
                
                Section {
                    Picker("Diameter", selection: $diameter) {
                        Text("1.75 mm").tag(1.75)
                        Text("2.85 mm").tag(2.85)
                    }
                    
                    TextField("Empty Spool Weight (g)", text: $emptySpoolWeight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Remaining Weight (g)", text: $remainingWeight)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Advanced")
                }
                
                Section {
                    TextField("Min Temp (°C)", text: $minTemp)
                        .keyboardType(.numberPad)
                    
                    TextField("Max Temp (°C)", text: $maxTemp)
                        .keyboardType(.numberPad)
                    
                    TextField("Bed Temp (°C)", text: $bedTemp)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Temperature Settings")
                }
            }
            .navigationTitle(filament == nil ? "Add Material" : "Edit Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brown)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFilament()
                    }
                    .foregroundColor(.teal)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let filament = filament {
                loadFilament(filament)
            }
        }
    }
    
    private func loadFilament(_ filament: Filament) {
        brand = filament.brand
        material = filament.material
        colorName = filament.colorName
        colorHex = filament.colorHex
        diameter = filament.diameter
        initialWeight = String(filament.initialWeight)
        remainingWeight = String(filament.remainingWeight)
        emptySpoolWeight = filament.emptySpoolWeight.map { String($0) } ?? ""
        price = filament.price.map { String(describing: $0) } ?? ""
        minTemp = filament.minTemp.map { String($0) } ?? ""
        maxTemp = filament.maxTemp.map { String($0) } ?? ""
        bedTemp = filament.bedTemp.map { String($0) } ?? ""
    }
    
    private func saveFilament() {
        let initial = Double(initialWeight) ?? 1000.0
        let remaining = Double(remainingWeight) ?? initial
        
        if let existing = filament {
            existing.brand = brand
            existing.material = material
            existing.colorName = colorName
            existing.colorHex = colorHex
            existing.diameter = diameter
            existing.initialWeight = initial
            existing.remainingWeight = remaining
            existing.emptySpoolWeight = Double(emptySpoolWeight)
            existing.price = Decimal(string: price)
            existing.minTemp = Int(minTemp)
            existing.maxTemp = Int(maxTemp)
            existing.bedTemp = Int(bedTemp)
        } else {
            let newFilament = Filament(
                brand: brand,
                material: material,
                colorName: colorName,
                colorHex: colorHex,
                diameter: diameter,
                initialWeight: initial,
                remainingWeight: remaining,
                emptySpoolWeight: Double(emptySpoolWeight),
                density: nil,
                minTemp: Int(minTemp),
                maxTemp: Int(maxTemp),
                bedTemp: Int(bedTemp),
                price: Decimal(string: price)
            )
            modelContext.insert(newFilament)
        }
        
        dismiss()
    }
}

struct ColorButton: View {
    let name: String
    let hex: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.teal : Color.clear, lineWidth: 3)
                )
        }
    }
}

#Preview {
    AddMaterialView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
