//
//  AddMaterialView.swift
//  FilamentTracker
//
//  Form for adding/editing filament material
//

import SwiftUI
import SwiftData
import UIKit

struct AddMaterialView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var colorName: String = ""
    @State private var brand: String = ""
    @State private var material: String = "PLA"
    @State private var colorHex: String = "#000000" // Default black
    @State private var diameter: Double = 1.75
    @State private var stockAmount: String = ""
    @State private var price: String = ""
    @State private var notes: String = ""
    
    // AI Recognition States
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isAnalyzing = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showActionSheet = false
    @State private var showBrandPicker = false
    @State private var showCustomMaterialInput = false
    @State private var customMaterial: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    
    let filament: Filament?
    let materials = ["PLA", "PLA+", "ABS", "PETG", "TPU", "ASA", "PA", "PC", "PVA", "HIPS", "Wood", "Carbon", "Silk", "Matte"]
    
    // Preset brands
    let presetBrands = ["Bambu Lab", "Polymaker", "Sunlu", "eSUN", "Creality", "Prusa", "Hatchbox", "Overture"]
    
    // Design colors matching the mockup - common filament colors
    let presetColors: [String] = [
        "#000000", // Black
        "#FFFFFF", // White
        "#FF0000", // Red
        "#0066FF", // Blue
        "#00AA00", // Green
        "#FFFF00", // Yellow
        "#FFA500", // Orange
        "#808080", // Gray
        "#A8D5BA", // Sage green
        "#C4A574", // Brown/tan
        "#FFC0CB", // Pink
        "#800080"  // Purple
    ]
    
    // Color name mapping for preset colors
    let colorNameMap: [String: String] = [
        "#000000": "Black",
        "#FFFFFF": "White",
        "#FF0000": "Red",
        "#0066FF": "Blue",
        "#00AA00": "Green",
        "#FFFF00": "Yellow",
        "#FFA500": "Orange",
        "#808080": "Gray",
        "#A8D5BA": "Sage Green",
        "#C4A574": "Brown",
        "#FFC0CB": "Pink",
        "#800080": "Purple"
    ]
    
    init(filament: Filament? = nil) {
        self.filament = filament
    }
    
    // Form validation
    private var isFormValid: Bool {
        !stockAmount.trimmingCharacters(in: .whitespaces).isEmpty
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
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // AI Recognition Banner
                            Button(action: {
                                showActionSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(String(localized: "material.auto.fill", bundle: .main))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text(String(localized: "material.auto.fill.subtitle", bundle: .main))
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
                                        gradient: Gradient(colors: [Color(hex: "#6B9B7A"), Color(hex: "#5A8A6A")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .confirmationDialog(String(localized: "material.choose.image.source", bundle: .main), isPresented: $showActionSheet) {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    Button(String(localized: "material.camera", bundle: .main)) {
                                        sourceType = .camera
                                        showImagePicker = true
                                    }
                                }
                                Button(String(localized: "material.photo.library", bundle: .main)) {
                                    sourceType = .photoLibrary
                                    showImagePicker = true
                                }
                                Button(String(localized: "cancel", bundle: .main), role: .cancel) {}
                            }
                            
                            // Material Type Section
                            FormSection(title: String(localized: "material.type", bundle: .main)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(materials, id: \.self) { mat in
                                                MaterialTypeChip(
                                                    title: mat,
                                                    isSelected: material == mat,
                                                    disabled: filament != nil
                                                ) {
                                                    if filament == nil {
                                                        material = mat
                                                        showCustomMaterialInput = false
                                                        customMaterial = ""
                                                    }
                                                }
                                            }
                                            
                                            // Custom/Other option - show as selected if material is custom
                                            MaterialTypeChip(
                                                title: !materials.contains(material) && !material.isEmpty ? material : "+",
                                                isSelected: !materials.contains(material) && !material.isEmpty,
                                                disabled: filament != nil
                                            ) {
                                                if filament == nil {
                                                    showCustomMaterialInput = true
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Custom material input - only show when explicitly triggered
                                    if showCustomMaterialInput && filament == nil {
                                        HStack {
                                            TextField(String(localized: "material.enter.custom.type", bundle: .main), text: $customMaterial)
                                                .textInputAutocapitalization(.never)
                                                .autocorrectionDisabled(false)
                                                .padding()
                                                .background(Color(.secondarySystemBackground))
                                                .cornerRadius(12)
                                            
                                            Button(action: {
                                                if !customMaterial.isEmpty {
                                                    material = customMaterial
                                                    showCustomMaterialInput = false
                                                }
                                            }) {
                                                Text(String(localized: "material.ok", bundle: .main))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(customMaterial.isEmpty ? Color.gray : Color(hex: "#6B9B7A"))
                                                    .cornerRadius(12)
                                            }
                                            .disabled(customMaterial.isEmpty)
                                        }
                                    }
                                }
                            }
                            
                            // Color Name Section
                            FormSection(title: String(localized: "material.color.name", bundle: .main)) {
                                SimpleTextField(
                                    placeholder: String(localized: "material.enter.name", bundle: .main),
                                    text: $colorName
                                )
                            }
                            
                            // Brand Section
                            FormSection(title: String(localized: "material.brand", bundle: .main)) {
                                Button(action: { showBrandPicker = true }) {
                                    HStack {
                                        Text(brand.isEmpty ? String(localized: "material.select.brand", bundle: .main) : brand)
                                            .foregroundColor(brand.isEmpty ? .secondary : .primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .sheet(isPresented: $showBrandPicker) {
                                    BrandSelectionView(
                                        selectedBrand: $brand,
                                        presetBrands: presetBrands
                                    )
                                }
                            }
                            
                            // Color Section
                            FormSection(title: String(localized: "material.color", bundle: .main)) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // Custom Color Picker
                                        VStack(spacing: 4) {
                                            ColorPicker("", selection: Binding(
                                                get: { Color(hex: colorHex) },
                                                set: { newColor in
                                                    if filament == nil, let hex = newColor.toHex() {
                                                        colorHex = hex
                                                    }
                                                }
                                            ), supportsOpacity: false)
                                            .labelsHidden()
                                            .frame(width: 40, height: 40)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .disabled(filament != nil)
                                        }
                                        
                                        // Preset Colors
                                        ForEach(presetColors, id: \.self) { color in
                                            SimpleColorButton(
                                                hex: color,
                                                isSelected: colorHex == color,
                                                disabled: filament != nil
                                            ) {
                                                if filament == nil {
                                                    colorHex = color
                                                    // Auto-fill color name if empty
                                                    if colorName.isEmpty, let name = colorNameMap[color] {
                                                        colorName = name
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            // Diameter Section
                            FormSection(title: String(localized: "material.diameter", bundle: .main)) {
                                DiameterPicker(selectedDiameter: $diameter)
                            }
                            
                            // Stock Amount & Price Section
                            HStack(spacing: 12) {
                                FormSection(title: String(localized: "material.stock.amount", bundle: .main)) {
                                    SuffixTextField(
                                        placeholder: "",
                                        text: $stockAmount,
                                        suffix: "kg",
                                        keyboardType: .decimalPad
                                    )
                                }
                                
                                FormSection(title: String(localized: "material.price", bundle: .main)) {
                                    SuffixTextField(
                                        placeholder: "",
                                        text: $price,
                                        suffix: "¥",
                                        keyboardType: .decimalPad
                                    )
                                }
                            }
                            
                            // Notes Section
                            FormSection(title: String(localized: "material.notes", bundle: .main), subtitle: String(localized: "material.optional", bundle: .main)) {
                                NotesTextField(
                                    placeholder: "",
                                    text: $notes
                                )
                            }
                            
                            // Spool Image
                            HStack {
                                Spacer()
                                Image("add.spool")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 160, height: 120)
                                    .foregroundColor(Color(hex: colorHex).opacity(0.6))
                                Spacer()
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                    
                    // Bottom Button
                    VStack(spacing: 12) {
                        Button(action: { saveFilament() }) {
                            Text(filament == nil ? String(localized: "material.add", bundle: .main) : String(localized: "material.update", bundle: .main))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isFormValid ? Color(hex: "#6B9B7A") : Color.gray.opacity(0.4))
                                .cornerRadius(12)
                        }
                        .disabled(!isFormValid)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Color(.systemBackground)
                            .opacity(0.95)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle(filament == nil ? String(localized: "material.add.new", bundle: .main) : String(localized: "material.edit.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if filament == nil {
                        Button(String(localized: "material.clear", bundle: .main)) {
                            clearForm()
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage, sourceType: sourceType)
                    .ignoresSafeArea()
            }
            .onChange(of: inputImage) { _, newImage in
                if let image = newImage {
                    analyzeImage(image)
                }
            }
            .alert("识别错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            if let filament = filament {
                loadFilament(filament)
            }
        }
    }
    
    private func clearForm() {
        colorName = ""
        brand = ""
        material = "PLA"
        colorHex = "#A8D5BA"
        diameter = 1.75
        stockAmount = ""
        price = ""
        notes = ""
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        
        Task {
            do {
                // Use real API recognizer
                let recognizedData = try await ImageRecognizer.shared.analyze(image)
                
                await MainActor.run {
                    withAnimation {
                        if let brand = recognizedData.brand { self.brand = brand }
                        if let material = recognizedData.material { self.material = material }
                        if let colorName = recognizedData.colorName { self.colorName = colorName }
                        if let colorHex = recognizedData.colorHex { self.colorHex = colorHex }
                        if let weight = recognizedData.weight {
                            // Convert g to kg
                            if let grams = Double(weight) {
                                self.stockAmount = String(format: "%.1f", grams / 1000.0)
                            }
                        }
                        if let diameter = recognizedData.diameter { self.diameter = diameter }
                        
                        // 将温度信息添加到notes字段
                        if let temperatureInfo = recognizedData.minTemp, !temperatureInfo.isEmpty {
                            // 如果notes已有内容，追加温度信息；否则直接设置
                            if !self.notes.isEmpty {
                                self.notes = "\(self.notes)\n\n温度信息: \(temperatureInfo)"
                            } else {
                                self.notes = "温度信息: \(temperatureInfo)"
                            }
                        }
                        
                        isAnalyzing = false
                    }
                }
            } catch let error as ImageRecognizerError {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = error.localizedDescription ?? "识别失败，请重试"
                    showErrorAlert = true
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func loadFilament(_ filament: Filament) {
        colorName = filament.colorName
        brand = filament.brand
        material = filament.material
        colorHex = filament.colorHex
        diameter = filament.diameter
        stockAmount = String(format: "%.1f", filament.initialWeight / 1000.0)
        price = filament.price.map { String(describing: $0) } ?? ""
        notes = filament.notes ?? ""
    }
    
    private func saveFilament() {
        let stockKg = Double(stockAmount) ?? 1.0
        let stockGrams = stockKg * 1000.0
        
        if let existing = filament {
            // 编辑模式下：只更新基础信息和总重量，保留已使用的重量，避免把使用率清零
            existing.brand = brand
            // existing.material = material  // Not allowed to change
            // existing.colorName = colorName  // Not allowed to change
            // existing.colorHex = colorHex  // Not allowed to change
            existing.diameter = diameter
            
            let previousRemaining = existing.remainingWeight
            existing.initialWeight = stockGrams
            // 如果用户调小了初始重量，确保剩余重量不会超过新的初始重量
            existing.remainingWeight = min(previousRemaining, stockGrams)
            
            // 不再清空空线盘重量，保留用户之前设置的数据
            existing.price = Decimal(string: price)
            existing.notes = notes.isEmpty ? nil : notes
        } else {
            let newFilament = Filament(
                brand: brand,
                material: material,
                colorName: colorName,
                colorHex: colorHex,
                diameter: diameter,
                initialWeight: stockGrams,
                remainingWeight: stockGrams,
                emptySpoolWeight: nil,
                density: nil,
                minTemp: nil,
                maxTemp: nil,
                bedTemp: nil,
                price: Decimal(string: price),
                notes: notes.isEmpty ? nil : notes
            )
            
            // Ensure we have a material-color configuration for this material type
            createMaterialColorConfigIfNeeded(for: material)
            
            modelContext.insert(newFilament)
        }
        
        dismiss()
    }
    
    /// Create a material-color configuration entry if this material type has not been seen before.
    private func createMaterialColorConfigIfNeeded(for material: String) {
        let trimmed = material.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Check if a config for this material already exists (case-insensitive)
        let descriptor = FetchDescriptor<MaterialColorConfig>()
        let existingConfigs = (try? modelContext.fetch(descriptor)) ?? []
        if existingConfigs.contains(where: { $0.material.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return
        }
        
        // Determine which colors are already used
        let usedColors = Set(existingConfigs.map { $0.colorHex.uppercased() })
        
        // Pick the first unused color from the default palette, otherwise fall back to a random one
        let palette = MaterialColorConfig.defaultPalette
        let availableColor = palette.first(where: { !usedColors.contains($0.uppercased()) })
            ?? palette.randomElement()
            ?? "#7FD4B0"
        
        let config = MaterialColorConfig(material: trimmed, colorHex: availableColor)
        modelContext.insert(config)
    }
}

// MARK: - Form Section
struct FormSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            content
        }
    }
}

// MARK: - Material Type Chip
struct MaterialTypeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var disabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : (disabled ? .secondary : .primary))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "#8B9A7D") : (disabled ? Color(.systemGray5) : Color(.systemBackground)))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(disabled ? 0.2 : 0.3), lineWidth: 1)
                )
        }
        .disabled(disabled)
    }
}

// MARK: - Simple TextField
struct SimpleTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(false)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Simple Color Button
struct SimpleColorButton: View {
    let hex: String
    let isSelected: Bool
    let action: () -> Void
    var disabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 40, height: 40)
                    .opacity(disabled ? 0.5 : 1.0)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color(hex: "#6B9B7A") : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(disabled)
    }
}

// MARK: - Diameter Picker
struct DiameterPicker: View {
    @Binding var selectedDiameter: Double
    
    var body: some View {
        Menu {
            Button("1.75mm") { selectedDiameter = 1.75 }
            Button("2.85mm") { selectedDiameter = 2.85 }
        } label: {
            HStack {
                Text(selectedDiameter == 1.75 ? "1.75mm" : "2.85mm")
                    .foregroundColor(.primary)
                
                Text(selectedDiameter == 1.75 ? "2.85mm" : "1.75mm")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Suffix TextField
struct SuffixTextField: View {
    let placeholder: String
    @Binding var text: String
    let suffix: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
            
            Text(suffix)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Notes TextField
struct NotesTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .frame(minHeight: 80)
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Legacy Components (kept for compatibility)
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
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(false)
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

// MARK: - Brand Selection View
struct BrandSelectionView: View {
    @Binding var selectedBrand: String
    let presetBrands: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var customBrand: String = ""
    @State private var isCustomMode: Bool = false
    
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
                        ForEach(presetBrands, id: \.self) { brand in
                            Button(action: {
                                selectedBrand = brand
                                dismiss()
                            }) {
                                HStack {
                                    // Brand initial letter
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "#6B9B7A").opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Text(String(brand.prefix(1)))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(hex: "#6B9B7A"))
                                    }
                                    
                                    Text(brand)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedBrand == brand {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "#6B9B7A"))
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Custom Brand Option
                        Button(action: {
                            isCustomMode = true
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(String(localized: "material.custom.brand", bundle: .main))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        
                        // Custom Input Field
                        if isCustomMode {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "material.enter.custom.brand", bundle: .main))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField(String(localized: "material.brand.name", bundle: .main), text: $customBrand)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(false)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    
                                    Button(action: {
                                        if !customBrand.isEmpty {
                                            selectedBrand = customBrand
                                            dismiss()
                                        }
                                    }) {
                                        Text(String(localized: "add", bundle: .main))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 14)
                                            .background(customBrand.isEmpty ? Color.gray : Color(hex: "#6B9B7A"))
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
            .navigationTitle(String(localized: "material.select.brand.title", bundle: .main))
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
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self, MaterialColorConfig.self], inMemory: true)
}
