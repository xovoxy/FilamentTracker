//
//  TrackUsageView.swift
//  FilamentTracker
//
//  View for logging filament usage - supports multiple filaments per print job
//

import SwiftUI
import SwiftData

// MARK: - Filament Usage Item
struct FilamentUsageItem: Identifiable {
    let id: UUID
    var filament: Filament
    var amountGrams: String
    
    init(id: UUID = UUID(), filament: Filament, amountGrams: String = "") {
        self.id = id
        self.filament = filament
        self.amountGrams = amountGrams
    }
}

struct TrackUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Filament> { !$0.isArchived }) private var filaments: [Filament]
    
    /// The filament that launched this sheet (used as default selection)
    let filament: Filament
    
    // PRINT DETAILS
    @State private var printJobName: String = ""
    
    // USAGE ITEMS - support multiple filaments
    @State private var usageItems: [FilamentUsageItem] = []
    
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
            .navigationTitle(String(localized: "usage.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "material.clear", bundle: .main)) {
                        clearForm()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                initializeItems()
            }
        }
    }
    
    // MARK: - PRINT DETAILS Card
    private var printDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "usage.print.details", bundle: .main))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Print Job Name
            FormRow(label: String(localized: "usage.print.job.name", bundle: .main)) {
                TextField(String(localized: "usage.enter.job.name", bundle: .main), text: $printJobName)
                    .textFieldStyle(UsageTextFieldStyle())
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
            HStack {
                Text(String(localized: "usage.usage.details", bundle: .main))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Add Filament Button
                Button(action: { addFilamentItem() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text(String(localized: "usage.add.spool", bundle: .main))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(hex: "#8BC5D9"))
                }
            }
            
            if usageItems.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(String(localized: "usage.no.spools.added", bundle: .main))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // List of filament usage items
                VStack(spacing: 12) {
                    ForEach(usageItems) { item in
                        FilamentUsageRow(
                            item: Binding(
                                get: { item },
                                set: { newItem in
                                    if let index = usageItems.firstIndex(where: { $0.id == item.id }) {
                                        usageItems[index] = newItem
                                    }
                                }
                            ),
                            filaments: filaments,
                            onDelete: {
                                deleteItem(item)
                            }
                        )
                    }
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
        Button(action: { saveUsage() }) {
            Text(String(localized: "usage.title", bundle: .main))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isValidForm
                        ? Color(hex: "#8BC5D9")
                        : Color.gray.opacity(0.4)
                )
                .cornerRadius(12)
        }
        .disabled(!isValidForm)
    }
    
    // MARK: - Validation
    private var isValidForm: Bool {
        !usageItems.isEmpty && usageItems.allSatisfy { item in
            if let amount = Double(item.amountGrams), amount > 0 {
                // Check that amount doesn't exceed remaining weight
                return amount <= item.filament.remainingWeight
            }
            return false
        }
    }
    
    // MARK: - Actions
    private func initializeItems() {
        // Initialize with the filament that launched this view
        if usageItems.isEmpty {
            if let match = filaments.first(where: { $0.id == filament.id }) {
                usageItems = [FilamentUsageItem(filament: match)]
            } else if let first = filaments.first {
                usageItems = [FilamentUsageItem(filament: first)]
            }
        }
    }
    
    private func addFilamentItem() {
        // Add a new item with the first available filament (or the default one)
        let defaultFilament = filaments.first(where: { $0.id == filament.id }) ?? filaments.first ?? filament
        usageItems.append(FilamentUsageItem(filament: defaultFilament))
    }
    
    private func deleteItem(_ item: FilamentUsageItem) {
        usageItems.removeAll { $0.id == item.id }
    }
    
    private func clearForm() {
        printJobName = ""
        usageItems.removeAll()
        initializeItems()
    }
    
    private func saveUsage() {
        guard isValidForm else { return }
        
        let jobName = printJobName.isEmpty ? nil : printJobName
        
        // Create UsageLog for each item
        for item in usageItems {
            guard let amount = Double(item.amountGrams), amount > 0 else { continue }
            
            let log = UsageLog(
                amount: amount,
                date: Date(),
                note: jobName,
                type: .print,
                filament: item.filament
            )
            
            modelContext.insert(log)
            
            // Update filament remaining weight
            item.filament.remainingWeight = max(0, item.filament.remainingWeight - amount)
            
            // Auto-archive if empty
            if item.filament.remainingWeight <= 0 {
                item.filament.isArchived = true
            }
        }
        
        dismiss()
    }
}

// MARK: - Filament Usage Row
struct FilamentUsageRow: View {
    @Binding var item: FilamentUsageItem
    let filaments: [Filament]
    let onDelete: () -> Void
    @State private var showFilamentPicker = false
    @State private var showAutoAdjustmentHint = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Filament Selection
            HStack {
                // Color indicator
                Circle()
                    .fill(Color(hex: item.filament.colorHex))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                
                // Filament info
                Button(action: { showFilamentPicker = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(item.filament.colorName) \(item.filament.material)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(item.filament.brand.isEmpty ? String(localized: "home.unknown.brand", bundle: .main) : item.filament.brand)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .sheet(isPresented: $showFilamentPicker) {
                    FilamentSelectionView(
                        filaments: filaments,
                        selectedFilament: Binding(
                            get: { item.filament },
                            set: { newFilament in
                                item.filament = newFilament
                            }
                        ),
                        initialFilament: item.filament
                    )
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
            
            // Amount input
            HStack {
                Text(String(localized: "usage.amount.used", bundle: .main))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 4) {
                    TextField("0", text: $item.amountGrams)
                        .textFieldStyle(UsageTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                        .onChange(of: item.amountGrams) { oldValue, newValue in
                            // Validate input - only allow numbers and decimal point
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered != newValue {
                                item.amountGrams = filtered
                                return
                            }
                            
                            // Auto-adjust if exceeds remaining weight
                            if let amount = Double(newValue), amount > item.filament.remainingWeight {
                                item.amountGrams = String(format: "%.0f", item.filament.remainingWeight)
                                showAutoAdjustmentHint = true
                                // Hide hint after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showAutoAdjustmentHint = false
                                }
                            }
                        }
                    
                    Text("g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Show remaining amount and auto-adjustment hint
            if let amount = Double(item.amountGrams), amount > 0 {
                let newRemaining = max(0, item.filament.remainingWeight - amount)
                
                VStack(spacing: 4) {
                    HStack {
                        Text(String(localized: "usage.remaining", bundle: .main))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(newRemaining))g")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(newRemaining < 50 ? .red : .primary)
                    }
                    
                    if showAutoAdjustmentHint {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(String(format: String(localized: "usage.auto.adjusted", bundle: .main), Int(item.filament.remainingWeight)))
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Show available amount hint
            HStack {
                Text(String(localized: "usage.available", bundle: .main))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(item.filament.remainingWeight))g")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
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

// MARK: - Usage Text Field Style
struct UsageTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Filament Selection Sheet
struct FilamentSelectionView: View {
    let filaments: [Filament]
    @Binding var selectedFilament: Filament
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
                                
                                HStack(spacing: 4) {
                                    Text(filament.brand.isEmpty ? String(localized: "home.unknown.brand", bundle: .main) : filament.brand)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(format: String(localized: "usage.remaining.weight", bundle: .main), Int(filament.remainingWeight)))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if filament.id == selectedFilament.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#6B9B7A"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "usage.select.spool", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel", bundle: .main)) {
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
