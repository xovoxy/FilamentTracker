//
//  DataMigrationView.swift
//  FilamentTracker
//
//  Data migration view for exporting and importing material data
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Export/Import Data Models
struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let filaments: [FilamentExportData]
    let materialColorConfigs: [MaterialColorConfigExportData]
    let appSettings: AppSettingsExportData?
}

struct FilamentExportData: Codable {
    let id: UUID
    let brand: String
    let material: String
    let colorName: String
    let colorHex: String
    let diameter: Double
    let initialWeight: Double
    let remainingWeight: Double
    let emptySpoolWeight: Double?
    let density: Double?
    let minTemp: Int?
    let maxTemp: Int?
    let bedTemp: Int?
    let price: Decimal?
    let purchaseDate: Date
    let isArchived: Bool
    let notes: String?
    let logs: [UsageLogExportData]
}

struct UsageLogExportData: Codable {
    let id: UUID
    let amount: Double
    let date: Date
    let note: String?
    let type: String
}

struct MaterialColorConfigExportData: Codable {
    let material: String
    let colorHex: String
}

struct AppSettingsExportData: Codable {
    let defaultDiameter: Double
    let lowStockThreshold: Double
    let currency: String
    let language: String
}

// MARK: - Data Migration View
struct DataMigrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var filaments: [Filament]
    @Query private var materialColorConfigs: [MaterialColorConfig]
    @Query private var appSettings: [AppSettings]
    
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportDocument: JSONDocument?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showImportOptions = false
    @State private var showHelp = false
    @State private var importMode: ImportMode = .merge
    @State private var pendingImportURL: URL?
    
    enum ImportMode {
        case merge      // 合并：保留现有数据
        case replace    // 替换：清空后导入
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer()
                            .frame(height: 20)
                        
                        // Export Section
                        exportSection
                            .padding(.horizontal)
                        
                        // Import Section
                        importSection
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(String(localized: "migration.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "FilamentTracker_Export_\(formattedDate()).json"
            ) { result in
                handleExportResult(result)
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportSelection(result)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button(String(localized: "ok", bundle: .main), role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showImportOptions) {
                importOptionsSheet
            }
            .sheet(isPresented: $showHelp) {
                helpSheet
            }
        }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "migration.export.title", bundle: .main))
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                exportData()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.doc")
                        .font(.title2)
                    Text(String(localized: "migration.export.button", bundle: .main))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#A0C49D"))
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
        .padding()
        .background(Color(hex: "#E8F5E9").opacity(0.5))
        .cornerRadius(20)
    }
    
    // MARK: - Import Section
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "migration.import.title", bundle: .main))
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                showImporter = true
            } label: {
                HStack {
                    Image(systemName: "arrow.up.doc")
                        .font(.title2)
                    Text(String(localized: "migration.import.button", bundle: .main))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#8BC5D9"))
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
        .padding()
        .background(Color(hex: "#E3F2FD").opacity(0.5))
        .cornerRadius(20)
    }
    
    // MARK: - JSON Example Section
    private var jsonExampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "migration.json.example", bundle: .main))
                .font(.headline)
            
            Text("""
            {
              "material": "PLA",
              "brand": "XYZ",
              "color": "Red",
              "diameter": "1.75mm",
              "stock": "10.5kg",
              "price": "¥50"
            }
            """)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.5))
        .cornerRadius(20)
    }
    
    // MARK: - How to Use Section
    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "migration.how.to.use", bundle: .main))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HowToStep(number: "1", text: String(localized: "migration.step.1", bundle: .main))
                HowToStep(number: "2", text: String(localized: "migration.step.2", bundle: .main))
                HowToStep(number: "3", text: String(localized: "migration.step.3", bundle: .main))
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.5))
        .cornerRadius(20)
    }
    
    // MARK: - Help Sheet
    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overview
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "migration.description", bundle: .main))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Export / Import descriptions
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "migration.export.title", bundle: .main))
                            .font(.headline)
                        Text(String(localized: "migration.export.description", bundle: .main))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text(String(localized: "migration.import.title", bundle: .main))
                            .font(.headline)
                        Text(String(localized: "migration.import.description", bundle: .main))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Import modes summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "migration.import.mode", bundle: .main))
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• " + String(localized: "migration.import.merge", bundle: .main))
                                .font(.subheadline)
                            Text(String(localized: "migration.import.merge.description", bundle: .main))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• " + String(localized: "migration.import.replace", bundle: .main))
                                .font(.subheadline)
                                .padding(.top, 4)
                            Text(String(localized: "migration.import.replace.description", bundle: .main))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "migration.how.to.use", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "archive.done", bundle: .main)) {
                        showHelp = false
                    }
                }
            }
        }
    }
    
    // MARK: - Import Options Sheet
    private var importOptionsSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        importMode = .merge
                        showImportOptions = false
                        if let url = pendingImportURL {
                            performImport(from: url, mode: .merge)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "migration.import.merge", bundle: .main))
                                    .font(.headline)
                                Text(String(localized: "migration.import.merge.description", bundle: .main))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if importMode == .merge {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Button {
                        importMode = .replace
                        showImportOptions = false
                        if let url = pendingImportURL {
                            performImport(from: url, mode: .replace)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "migration.import.replace", bundle: .main))
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(String(localized: "migration.import.replace.description", bundle: .main))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if importMode == .replace {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "migration.import.mode", bundle: .main))
                }
            }
            .navigationTitle(String(localized: "migration.import.options", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "cancel", bundle: .main)) {
                        showImportOptions = false
                        pendingImportURL = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Export Function
    private func exportData() {
        let exportData = createExportData()
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(exportData)
            
            exportDocument = JSONDocument(data: jsonData)
            showExporter = true
        } catch {
            alertTitle = String(localized: "migration.export.error", bundle: .main)
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func createExportData() -> ExportData {
        // Convert Filaments with their logs
        let filamentsData = filaments.map { filament -> FilamentExportData in
            let logsData = filament.logs.map { log -> UsageLogExportData in
                UsageLogExportData(
                    id: log.id,
                    amount: log.amount,
                    date: log.date,
                    note: log.note,
                    type: log.type
                )
            }
            
            return FilamentExportData(
                id: filament.id,
                brand: filament.brand,
                material: filament.material,
                colorName: filament.colorName,
                colorHex: filament.colorHex,
                diameter: filament.diameter,
                initialWeight: filament.initialWeight,
                remainingWeight: filament.remainingWeight,
                emptySpoolWeight: filament.emptySpoolWeight,
                density: filament.density,
                minTemp: filament.minTemp,
                maxTemp: filament.maxTemp,
                bedTemp: filament.bedTemp,
                price: filament.price,
                purchaseDate: filament.purchaseDate,
                isArchived: filament.isArchived,
                notes: filament.notes,
                logs: logsData
            )
        }
        
        // Convert MaterialColorConfigs
        let colorConfigsData = materialColorConfigs.map { config in
            MaterialColorConfigExportData(
                material: config.material,
                colorHex: config.colorHex
            )
        }
        
        // Convert AppSettings
        let settingsData: AppSettingsExportData? = appSettings.first.map { settings in
            AppSettingsExportData(
                defaultDiameter: settings.defaultDiameter,
                lowStockThreshold: settings.lowStockThreshold,
                currency: settings.currency,
                language: settings.language
            )
        }
        
        return ExportData(
            version: "1.0",
            exportDate: Date(),
            filaments: filamentsData,
            materialColorConfigs: colorConfigsData,
            appSettings: settingsData
        )
    }
    
    // MARK: - Import Functions
    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            pendingImportURL = url
            showImportOptions = true
        case .failure(let error):
            alertTitle = String(localized: "migration.import.error", bundle: .main)
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func performImport(from url: URL, mode: ImportMode) {
        // On iOS, URLs from the document picker are security-scoped.
        // We must explicitly start / stop accessing them.
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard accessGranted else {
            alertTitle = String(localized: "migration.import.error", bundle: .main)
            alertMessage = String(localized: "migration.import.no.permission", bundle: .main)
            showAlert = true
            pendingImportURL = nil
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importData = try decoder.decode(ExportData.self, from: data)
            
            // Clear existing data if replace mode
            if mode == .replace {
                clearAllData()
            }
            
            // Import data
            importFilaments(importData.filaments, mode: mode)
            importMaterialColorConfigs(importData.materialColorConfigs, mode: mode)
            if let settings = importData.appSettings {
                importAppSettings(settings, mode: mode)
            }
            
            try modelContext.save()
            
            alertTitle = String(localized: "migration.import.success", bundle: .main)
            alertMessage = String(format: String(localized: "migration.import.success.message", bundle: .main), importData.filaments.count)
            showAlert = true
            
        } catch {
            alertTitle = String(localized: "migration.import.error", bundle: .main)
            alertMessage = error.localizedDescription
            showAlert = true
        }
        
        pendingImportURL = nil
    }
    
    private func clearAllData() {
        // Delete all filaments (will cascade delete logs)
        for filament in filaments {
            modelContext.delete(filament)
        }
        
        // Delete all color configs
        for config in materialColorConfigs {
            modelContext.delete(config)
        }
    }
    
    private func importFilaments(_ filamentsData: [FilamentExportData], mode: ImportMode) {
        for filamentData in filamentsData {
            // Check if filament already exists (by ID)
            if mode == .merge {
                let existingFilament = filaments.first { $0.id == filamentData.id }
                if existingFilament != nil {
                    continue // Skip if already exists in merge mode
                }
            }
            
            // Create new filament
            let newFilament = Filament(
                id: filamentData.id,
                brand: filamentData.brand,
                material: filamentData.material,
                colorName: filamentData.colorName,
                colorHex: filamentData.colorHex,
                diameter: filamentData.diameter,
                initialWeight: filamentData.initialWeight,
                remainingWeight: filamentData.remainingWeight,
                emptySpoolWeight: filamentData.emptySpoolWeight,
                density: filamentData.density,
                minTemp: filamentData.minTemp,
                maxTemp: filamentData.maxTemp,
                bedTemp: filamentData.bedTemp,
                price: filamentData.price,
                purchaseDate: filamentData.purchaseDate,
                isArchived: filamentData.isArchived,
                notes: filamentData.notes
            )
            
            modelContext.insert(newFilament)
            
            // Import logs for this filament
            for logData in filamentData.logs {
                let newLog = UsageLog(
                    id: logData.id,
                    amount: logData.amount,
                    date: logData.date,
                    note: logData.note,
                    type: UsageType(rawValue: logData.type) ?? .print,
                    filament: newFilament
                )
                modelContext.insert(newLog)
            }
        }
    }
    
    private func importMaterialColorConfigs(_ configsData: [MaterialColorConfigExportData], mode: ImportMode) {
        for configData in configsData {
            if mode == .merge {
                let existingConfig = materialColorConfigs.first { $0.material == configData.material }
                if existingConfig != nil {
                    continue // Skip if already exists
                }
            }
            
            let newConfig = MaterialColorConfig(
                material: configData.material,
                colorHex: configData.colorHex
            )
            modelContext.insert(newConfig)
        }
    }
    
    private func importAppSettings(_ settingsData: AppSettingsExportData, mode: ImportMode) {
        if mode == .merge, let existingSettings = appSettings.first {
            // Update existing settings
            existingSettings.defaultDiameter = settingsData.defaultDiameter
            existingSettings.lowStockThreshold = settingsData.lowStockThreshold
            existingSettings.currency = settingsData.currency
            existingSettings.language = settingsData.language
        } else {
            // Create new settings (or replace)
            if mode == .replace, let existingSettings = appSettings.first {
                modelContext.delete(existingSettings)
            }
            
            let newSettings = AppSettings(
                defaultDiameter: settingsData.defaultDiameter,
                lowStockThreshold: settingsData.lowStockThreshold,
                currency: settingsData.currency,
                language: Language(rawValue: settingsData.language) ?? .system
            )
            modelContext.insert(newSettings)
        }
    }
    
    // MARK: - Helper Functions
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            alertTitle = String(localized: "migration.export.success", bundle: .main)
            alertMessage = String(localized: "migration.export.success.message", bundle: .main)
            showAlert = true
        case .failure(let error):
            alertTitle = String(localized: "migration.export.error", bundle: .main)
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - How to Step Component
struct HowToStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number + ".")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - JSON Document for FileExporter
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview
#Preview {
    DataMigrationView()
        .modelContainer(for: [Filament.self, UsageLog.self, MaterialColorConfig.self, AppSettings.self], inMemory: true)
}
