//
//  TrackUsageView.swift
//  FilamentTracker
//
//  View for logging filament usage
//

import SwiftUI
import SwiftData

struct TrackUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let filament: Filament
    
    @State private var inputMethod: InputMethod = .byAmount
    @State private var amount: String = ""
    @State private var length: String = ""
    @State private var grossWeight: String = ""
    @State private var note: String = ""
    @State private var usageType: UsageType = .print
    
    enum InputMethod: String, CaseIterable {
        case byAmount = "By Amount"
        case byLength = "By Length"
        case byWeight = "By Weight"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Input Method", selection: $inputMethod) {
                        ForEach(InputMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    switch inputMethod {
                    case .byAmount:
                        TextField("Amount Used (g)", text: $amount)
                            .keyboardType(.decimalPad)
                        
                    case .byLength:
                        TextField("Length Used (m)", text: $length)
                            .keyboardType(.decimalPad)
                        
                    case .byWeight:
                        TextField("Current Gross Weight (g)", text: $grossWeight)
                            .keyboardType(.decimalPad)
                        
                        if let emptyWeight = filament.emptySpoolWeight {
                            Text("Empty Spool: \(Int(emptyWeight))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Empty spool weight not set")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Usage Entry")
                }
                
                Section {
                    TextField("Project Name (optional)", text: $note)
                    
                    Picker("Type", selection: $usageType) {
                        ForEach(UsageType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                } header: {
                    Text("Context")
                }
                
                Section {
                    HStack {
                        Text("Previous Remaining")
                        Spacer()
                        Text("\(Int(filament.remainingWeight))g")
                            .foregroundColor(.secondary)
                    }
                    
                    if let calculatedAmount = calculatedAmount {
                        HStack {
                            Text("Amount to Deduct")
                            Spacer()
                            Text("\(Int(calculatedAmount))g")
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("New Remaining")
                            Spacer()
                            Text("\(Int(max(0, filament.remainingWeight - calculatedAmount)))g")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Log Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveUsage()
                    }
                    .disabled(calculatedAmount == nil || calculatedAmount! <= 0)
                }
            }
        }
    }
    
    private var calculatedAmount: Double? {
        switch inputMethod {
        case .byAmount:
            return Double(amount)
            
        case .byLength:
            guard let lengthValue = Double(length) else {
                return nil
            }
            let density = filament.density ?? FilamentCalculator.density(for: filament.material)
            return FilamentCalculator.lengthToWeight(
                lengthMeters: lengthValue,
                diameter: filament.diameter,
                density: density
            )
            
        case .byWeight:
            guard let grossWeightValue = Double(grossWeight),
                  let emptyWeight = filament.emptySpoolWeight else {
                return nil
            }
            return FilamentCalculator.calculateUsedAmount(
                previousRemaining: filament.remainingWeight,
                currentGrossWeight: grossWeightValue,
                emptySpoolWeight: emptyWeight
            )
        }
    }
    
    private func saveUsage() {
        guard let amount = calculatedAmount, amount > 0 else { return }
        
        let log = UsageLog(
            amount: amount,
            date: Date(),
            note: note.isEmpty ? nil : note,
            type: usageType,
            filament: filament
        )
        
        modelContext.insert(log)
        
        // Update filament remaining weight
        filament.remainingWeight = max(0, filament.remainingWeight - amount)
        
        // Auto-archive if empty
        if filament.remainingWeight <= 0 {
            filament.isArchived = true
        }
        
        dismiss()
    }
}

#Preview {
    TrackUsageView(filament: Filament(
        brand: "Bambu Lab",
        material: "PLA",
        colorName: "Black",
        colorHex: "#000000",
        initialWeight: 1000,
        remainingWeight: 750,
        emptySpoolWeight: 200
    ))
    .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
