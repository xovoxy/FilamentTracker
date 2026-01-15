//
//  TrackUsageView.swift
//  FilamentTracker
//
//  View for logging filament usage - redesigned to match design spec
//

import SwiftUI
import SwiftData

struct TrackUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Filament> { !$0.isArchived }) private var filaments: [Filament]
    
    /// The filament that launched this sheet (used as default selection)
    let filament: Filament
    
    // Selection
    @State private var selectedFilament: Filament?
    @State private var showFilamentPicker = false
    
    // PRINT DETAILS
    @State private var printJobName: String = ""
    
    // USAGE DETAILS (grams only)
    @State private var amountGrams: String = ""
    
    init(filament: Filament) {
        self.filament = filament
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#EBEBE0"),
                        Color(hex: "#E0EBF0")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // PRINT DETAILS Card
                            printDetailsCard
                            
                            // USAGE DETAILS Card
                            usageDetailsCard
                            
                            // MATERIAL PREVIEW Card
                            materialPreviewCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    
                    // Bottom Buttons
                    bottomButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#EBEBE0").opacity(0.95),
                                    Color(hex: "#E0EBF0").opacity(0.95)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .navigationTitle("Log Usage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") {
                        clearForm()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                initializeSelection()
            }
        }
    }
    
    // MARK: - PRINT DETAILS Card
    private var printDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRINT DETAILS")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let currentFilament = selectedFilament ?? filament
            
            // Print Job Name
            FormRow(label: "Print Job Name") {
                TextField("Enter job name.", text: $printJobName)
                    .textFieldStyle(UsageTextFieldStyle())
            }
            
            // Select Spool
            FormRow(label: "Spool") {
                Button(action: { showFilamentPicker = true }) {
                    HStack {
                        Text("\(currentFilament.colorName) \(currentFilament.material)")
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .sheet(isPresented: $showFilamentPicker) {
                    FilamentSelectionView(
                        filaments: filaments,
                        selectedFilament: $selectedFilament,
                        initialFilament: filament
                    )
                }
            }
            
            // Material Brand
            FormRow(label: "Material Brand") {
                ValuePill(text: currentFilament.brand.isEmpty ? "Unknown" : currentFilament.brand)
            }
            
            // Color
            FormRow(label: "Color") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: currentFilament.colorHex))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    ValuePill(text: currentFilament.colorName.isEmpty ? "Color" : currentFilament.colorName)
                }
            }
            
            // Diameter
            FormRow(label: "Diameter") {
                ValuePill(
                    text: String(format: "%.2fmm", currentFilament.diameter)
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - USAGE DETAILS Card
    private var usageDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("USAGE DETAILS")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Amount Used (grams)
            FormRow(label: "Amount Used") {
                HStack(spacing: 4) {
                    TextField("", text: $amountGrams)
                        .textFieldStyle(UsageTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    Text("g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - MATERIAL PREVIEW Card
    private var materialPreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MATERIAL PREVIEW")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let currentFilament = selectedFilament ?? filament
            let newRemaining: Double = {
                guard let used = calculatedAmount else { return currentFilament.remainingWeight }
                return max(0, currentFilament.remainingWeight - used)
            }()
            
            HStack(spacing: 16) {
                // Spool Image
                Image("usage.spool")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 90)
                    .foregroundColor(Color(hex: currentFilament.colorHex).opacity(0.6))
                
                Spacer()
                
                // Current Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Amount:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(newRemaining))g")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        // 单一 Log Usage 主按钮
        Button(action: { saveUsage() }) {
            Text("Log Usage")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    calculatedAmount != nil && calculatedAmount! > 0
                        ? Color(hex: "#8BC5D9")
                        : Color.gray.opacity(0.4)
                )
                .cornerRadius(12)
        }
        .disabled(calculatedAmount == nil || calculatedAmount! <= 0)
    }
    
    // MARK: - Calculation
    private var calculatedAmount: Double? {
        guard let value = Double(amountGrams), value > 0 else { return nil }
        return value
    }
    
    // MARK: - Actions
    private func initializeSelection() {
        // Prefer the filament passed in, but allow switching to any active filament
        if selectedFilament == nil {
            if let match = filaments.first(where: { $0.id == filament.id }) {
                selectedFilament = match
            } else {
                selectedFilament = filaments.first ?? filament
            }
        }
    }
    
    private func clearForm() {
        printJobName = ""
        amountGrams = ""
        // 保持当前选中的耗材不变，只清空当前这次打印的信息
    }
    
    private func saveUsage() {
        guard let amount = calculatedAmount, amount > 0 else { return }
        let targetFilament = selectedFilament ?? filament
        
        let log = UsageLog(
            amount: amount,
            date: Date(),
            note: printJobName.isEmpty ? nil : printJobName,
            type: .print,
            filament: targetFilament
        )
        
        modelContext.insert(log)
        
        // Update filament remaining weight
        targetFilament.remainingWeight = max(0, targetFilament.remainingWeight - amount)
        
        // Auto-archive if empty
        if targetFilament.remainingWeight <= 0 {
            targetFilament.isArchived = true
        }
        
        dismiss()
    }
}

// MARK: - Form Row
struct FormRow<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            content
        }
    }
}

// MARK: - Value Pill (read-only value styled like field)
struct ValuePill: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.primary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// MARK: - Usage Text Field Style
struct UsageTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// MARK: - Filament Selection Sheet
struct FilamentSelectionView: View {
    let filaments: [Filament]
    @Binding var selectedFilament: Filament?
    let initialFilament: Filament
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filaments) { filament in
                    Button {
                        selectedFilament = filament
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: filament.colorHex))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(filament.colorName) \(filament.material)")
                                    .foregroundColor(.primary)
                                
                                Text(filament.brand)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if filament.id == (selectedFilament?.id ?? initialFilament.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#6B9B7A"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Spool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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
