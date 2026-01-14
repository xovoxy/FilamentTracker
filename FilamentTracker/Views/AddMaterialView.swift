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
    @State private var price: String = ""
    @State private var minTemp: String = ""
    @State private var maxTemp: String = ""
    @State private var bedTemp: String = ""
    
    // AI Recognition States
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isAnalyzing = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showActionSheet = false
    @State private var showBrandPicker = false
    
    let filament: Filament?
    let materials = ["PLA", "PETG", "ABS", "TPU", "Other"]
    
    // Preset brands with logo asset names (use SF Symbols as fallback)
    let presetBrands: [(name: String, logo: String, isAsset: Bool)] = [
        ("Bambu Lab", "bambulab-logo", true),
        ("Polymaker", "polymaker-logo", true),
        ("Sunlu", "sunlu-logo", true),
        ("eSUN", "esun-logo", true),
        ("Creality", "creality-logo", true),
        ("Prusa", "prusa-logo", true),
        ("Hatchbox", "hatchbox-logo", true),
        ("Overture", "overture-logo", true),
        ("Other", "ellipsis.circle", false)
    ]
    
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
    
    // Form validation
    private var isFormValid: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !initialWeight.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#EBEBE0"), // Warm beige
                        Color(hex: "#E0EBF0")  // Cool beige/blue
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // AI Recognition Banner
                            Button(action: {
                                showActionSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Auto-fill from Photo")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text("Take a photo of the spool label")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                    
                                    if isAnalyzing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.teal, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 8)
                            .confirmationDialog("Choose Image Source", isPresented: $showActionSheet) {
                                Button("Camera") {
                                    sourceType = .camera
                                    showImagePicker = true
                                }
                                Button("Photo Library") {
                                    sourceType = .photoLibrary
                                    showImagePicker = true
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                            
                            // Material Name Section
                            SectionCard(title: "Basic Info") {
                                VStack(spacing: 12) {
                                    // Brand Picker Button
                                    Button(action: { showBrandPicker = true }) {
                                        HStack {
                                            // Brand Logo
                                            if let selectedBrand = presetBrands.first(where: { $0.name == brand }) {
                                                if selectedBrand.isAsset, let _ = UIImage(named: selectedBrand.logo) {
                                                    Image(selectedBrand.logo)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 24, height: 24)
                                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                                } else {
                                                    // Show first letter
                                                    Text(String(brand.prefix(1)))
                                                        .font(.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.teal)
                                                        .frame(width: 24, height: 24)
                                                }
                                            } else if !brand.isEmpty {
                                                // Custom brand - show first letter
                                                Text(String(brand.prefix(1)))
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.teal)
                                                    .frame(width: 24, height: 24)
                                            } else {
                                                Image(systemName: "building.2")
                                                    .foregroundColor(.teal)
                                                    .frame(width: 24, height: 24)
                                            }
                                            
                                            Text(brand.isEmpty ? "Select Brand" : brand)
                                                .foregroundColor(brand.isEmpty ? .secondary.opacity(0.7) : .primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                    .sheet(isPresented: $showBrandPicker) {
                                        BrandPickerView(selectedBrand: $brand, presetBrands: presetBrands)
                                    }
                                    
                                    // Material Type Picker
                                    HStack {
                                        Image(systemName: "cube.box")
                                            .foregroundColor(.teal)
                                            .frame(width: 24)
                                        
                                        Text("Material Type")
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Picker("Material", selection: $material) {
                                            ForEach(materials, id: \.self) { mat in
                                                Text(mat).tag(mat)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.primary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                    
                                    CustomTextField(
                                        icon: "paintpalette",
                                        title: "Color Name",
                                        text: $colorName
                                    )
                                    
                                    // Color Picker
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Color Preset")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 4)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(alignment: .top, spacing: 12) {
                                                // Custom Color Picker
                                                VStack(spacing: 4) {
                                                    ColorPicker("", selection: Binding(
                                                        get: { Color(hex: colorHex) },
                                                        set: { newColor in
                                                            if let hex = newColor.toHex() {
                                                                colorHex = hex
                                                            }
                                                        }
                                                    ), supportsOpacity: false)
                                                    .labelsHidden()
                                                    .frame(width: 44, height: 44)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                    )
                                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                    
                                                    Text("Custom")
                                                        .font(.caption2)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                }
                                                
                                                ForEach(presetColors, id: \.0) { color in
                                                    ColorButton(
                                                        name: color.0,
                                                        hex: color.1,
                                                        isSelected: colorHex == color.1
                                                    ) {
                                                        // Update both hex and name
                                                        colorHex = color.1
                                                        colorName = color.0
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 4)
                                        }
                                    }
                                }
                            }
                            
                            // Specifications Section
                            SectionCard(title: "Specifications & Cost") {
                                VStack(spacing: 12) {
                                    // Diameter Picker
                                    HStack {
                                        Image(systemName: "circle.diameter")
                                            .foregroundColor(.teal)
                                            .frame(width: 24)
                                        
                                        Text("Diameter")
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Picker("Diameter", selection: $diameter) {
                                            Text("1.75 mm").tag(1.75)
                                            Text("2.85 mm").tag(2.85)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 150)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                    
                                    CustomTextField(
                                        icon: "scalemass",
                                        title: "Initial Weight (g)",
                                        text: $initialWeight,
                                        keyboardType: .decimalPad
                                    )
                                    
                                    CustomTextField(
                                        icon: "arrow.down.circle",
                                        title: "Remaining Weight (g)",
                                        text: $remainingWeight,
                                        keyboardType: .decimalPad
                                    )
                                    
                                    CustomTextField(
                                        icon: "tag",
                                        title: "Cost",
                                        text: $price,
                                        keyboardType: .decimalPad
                                    )
                                }
                            }
                            
                            // Temperature Section
                            SectionCard(title: "Temperatures (°C)") {
                                HStack(spacing: 12) {
                                    CustomTextField(
                                        icon: "thermometer.snowflake",
                                        title: "Min",
                                        text: $minTemp,
                                        keyboardType: .numberPad
                                    )
                                    
                                    CustomTextField(
                                        icon: "thermometer.sun",
                                        title: "Max",
                                        text: $maxTemp,
                                        keyboardType: .numberPad
                                    )
                                    
                                    CustomTextField(
                                        icon: "bed.double",
                                        title: "Bed",
                                        text: $bedTemp,
                                        keyboardType: .numberPad
                                    )
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 80) // Space for bottom buttons
                    }
                    
                    // Bottom Buttons
                    HStack(spacing: 16) {
                        // Cancel Button
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemGray5))
                                .cornerRadius(16)
                        }
                        
                        // Save Button
                        Button(action: { saveFilament() }) {
                            Text("Save Material")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isFormValid ? Color(hex: "#2EAA7F") : Color.gray.opacity(0.5))
                                .cornerRadius(16)
                                .shadow(color: isFormValid ? Color(hex: "#2EAA7F").opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                        }
                        .disabled(!isFormValid)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#EBEBE0").opacity(0.95),
                                Color(hex: "#E0EBF0").opacity(0.95)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle(filament == nil ? "Add Material" : "Edit Material")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage, sourceType: sourceType)
                    .ignoresSafeArea()
            }
            .onChange(of: inputImage) { _, newImage in
                if let image = newImage {
                    analyzeImage(image)
                }
            }
        }
        .onAppear {
            if let filament = filament {
                loadFilament(filament)
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        
        Task {
            do {
                let recognizedData = try await MockImageRecognizer.shared.analyze(image)
                
                await MainActor.run {
                    withAnimation {
                        if let brand = recognizedData.brand { self.brand = brand }
                        if let material = recognizedData.material { self.material = material }
                        if let colorName = recognizedData.colorName { self.colorName = colorName }
                        if let colorHex = recognizedData.colorHex { self.colorHex = colorHex }
                        if let weight = recognizedData.weight {
                            self.initialWeight = weight
                            self.remainingWeight = weight
                        }
                        if let diameter = recognizedData.diameter { self.diameter = diameter }
                        if let minTemp = recognizedData.minTemp { self.minTemp = minTemp }
                        if let maxTemp = recognizedData.maxTemp { self.maxTemp = maxTemp }
                        if let bedTemp = recognizedData.bedTemp { self.bedTemp = bedTemp }
                        
                        isAnalyzing = false
                    }
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    // TODO: Handle error state
                }
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
            existing.emptySpoolWeight = nil
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
                emptySpoolWeight: nil,
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

// MARK: - Helper Components

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.teal)
                .frame(width: 24)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                TextField("", text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ColorButton: View {
    let name: String
    let hex: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.teal : Color.gray.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .clear)
            }
        }
    }
}

// MARK: - Brand Picker View
struct BrandPickerView: View {
    @Binding var selectedBrand: String
    let presetBrands: [(name: String, logo: String, isAsset: Bool)]
    @Environment(\.dismiss) private var dismiss
    @State private var customBrand: String = ""
    @State private var showCustomInput: Bool = false
    
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
                
                ScrollView {
                    VStack(spacing: 12) {
                        // Preset Brands
                        ForEach(presetBrands, id: \.name) { brand in
                            Button(action: {
                                if brand.name == "Other" {
                                    showCustomInput = true
                                } else {
                                    selectedBrand = brand.name
                                    dismiss()
                                }
                            }) {
                                HStack(spacing: 16) {
                                    // Brand Logo
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .frame(width: 48, height: 48)
                                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        
                                        if brand.isAsset, let _ = UIImage(named: brand.logo) {
                                            Image(brand.logo)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 36, height: 36)
                                        } else {
                                            // Fallback: Show first letter of brand name
                                            Text(String(brand.name.prefix(1)))
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .foregroundColor(.teal)
                                        }
                                    }
                                    
                                    Text(brand.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedBrand == brand.name {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.teal)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Custom Brand Input
                        if showCustomInput {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter Custom Brand")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                
                                HStack {
                                    TextField("Brand name", text: $customBrand)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    
                                    Button(action: {
                                        if !customBrand.isEmpty {
                                            selectedBrand = customBrand
                                            dismiss()
                                        }
                                    }) {
                                        Text("Add")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 14)
                                            .background(customBrand.isEmpty ? Color.gray : Color(hex: "#2EAA7F"))
                                            .cornerRadius(12)
                                    }
                                    .disabled(customBrand.isEmpty)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Brand")
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

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != 1.0 {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

#Preview {
    AddMaterialView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
