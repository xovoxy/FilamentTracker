//
//  HomeView.swift
//  FilamentTracker
//
//  Home page view matching the new design
//

import SwiftUI
import SwiftData
import Charts
import UIKit

// MARK: - Filament Group Model
struct FilamentGroup: Identifiable {
    let id: String
    let colorName: String
    let colorHex: String
    let material: String
    let filaments: [Filament]
    
    init(colorName: String, colorHex: String, material: String, filaments: [Filament]) {
        self.id = "\(colorName)-\(material)"
        self.colorName = colorName
        self.colorHex = colorHex
        self.material = material
        self.filaments = filaments
    }
    
    var totalCount: Int {
        filaments.count
    }
    
    var totalRemaining: Double {
        filaments.reduce(0) { $0 + $1.remainingWeight }
    }
    
    var totalInitial: Double {
        filaments.reduce(0) { $0 + $1.initialWeight }
    }
    
    var totalUsed: Double {
        totalInitial - totalRemaining
    }
    
    var averagePercentage: Double {
        guard totalInitial > 0 else { return 0 }
        return (totalRemaining / totalInitial) * 100
    }
    
    var allLogs: [UsageLog] {
        filaments.flatMap { $0.logs }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Filament> { !$0.isArchived }) private var filaments: [Filament]
    @Query private var usageLogs: [UsageLog]
    @Query private var appSettings: [AppSettings]
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    @State private var showAddMaterial = false
    @State private var showLogUsage = false
    @State private var showMenu = false
    @State private var showArchiveManagement = false
    @State private var showProfile = false
    @State private var showLanguagePicker = false
    @State private var showSettings = false
    @State private var showStatistics = false
    @State private var showDataMigration = false
    @State private var selectedGroup: FilamentGroup?
    @State private var groupToEdit: FilamentGroup?
    @State private var groupToArchive: FilamentGroup?
    @State private var showArchiveAlert = false
    @State private var selectedMaterialFilter: String? = nil
    
    // Get filtered filaments based on material filter
    var filteredFilaments: [Filament] {
        if let selectedMaterial = selectedMaterialFilter {
            return filaments.filter { $0.material == selectedMaterial }
        } else {
            return filaments
        }
    }
    
    // Calculate total stock count (based on filter)
    var totalStock: Int {
        filteredFilaments.count
    }
    
    // Calculate total usage in grams (based on filter)
    var totalUsage: Double {
        // Filter usage logs to only include those from filtered filaments
        let filteredLogs = usageLogs.filter { log in
            guard let filament = log.filament else { return false }
            
            // If material filter is selected, check if filament's material matches
            if let selectedMaterial = selectedMaterialFilter {
                return filament.material == selectedMaterial
            } else {
                return true
            }
        }
        
        return filteredLogs.reduce(0) { $0 + $1.amount }
    }
    
    // Find most used color (by usage amount, not count)
    var mostUsedColor: (color: String, material: String, colorHex: String, percentage: Double)? {
        guard !groupedFilaments.isEmpty, totalUsage > 0 else { return nil }
        
        guard let mostUsedGroup = groupedFilaments.max(by: { $0.totalUsed < $1.totalUsed }) else {
            return nil
        }
        
        let percentage = (mostUsedGroup.totalUsed / totalUsage) * 100.0
        return (mostUsedGroup.colorName, mostUsedGroup.material, mostUsedGroup.colorHex, percentage)
    }
    
    // Group filaments by color and material
    var groupedFilaments: [FilamentGroup] {
        let grouped = Dictionary(grouping: filaments) { filament in
            "\(filament.colorName)-\(filament.material)"
        }
        
        let allGroups = grouped.compactMap { (_, filaments) -> FilamentGroup? in
            guard let first = filaments.first else { return nil }
            // Sort filaments by remaining weight (descending)
            let sortedFilaments = filaments.sorted { $0.remainingWeight > $1.remainingWeight }
            return FilamentGroup(
                colorName: first.colorName,
                colorHex: first.colorHex,
                material: first.material,
                filaments: sortedFilaments
            )
        }
        
        // Apply material filter if selected
        if let selectedMaterial = selectedMaterialFilter {
            return allGroups.filter { $0.material == selectedMaterial }
                .sorted { $0.averagePercentage < $1.averagePercentage }
        } else {
            return allGroups.sorted { $0.averagePercentage < $1.averagePercentage }
        }
    }
    
    // Get all available material types
    var availableMaterials: [String] {
        let materials = Set(filaments.map { $0.material })
        return Array(materials).sorted()
    }
    
    // Archive all filaments in a group
    private func archiveGroup(_ group: FilamentGroup) {
        for filament in group.filaments {
            filament.isArchived = true
        }
        try? modelContext.save()
        groupToArchive = nil
    }
    
    // Format usage value - use kg if >= 1000g, otherwise use g
    private func formatUsage(_ grams: Double) -> String {
        if grams >= 1000 {
            return String(format: "%.1f kg", grams / 1000.0)
        } else {
            return String(format: "%.0f g", grams)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient from top-left to bottom-right
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#EBEBE0"), // Warm beige at top-left
                        Color(hex: "#E0EBF0")  // Cool beige with light blue hint at bottom-right
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Summary Cards Section - Fixed at top
                    summaryCardsSection
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    
                    // Current Inventory Section - Scrollable
                    currentInventorySection
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Action Buttons Section - Fixed at bottom
                    actionButtonsSection
                        .padding(.horizontal)
                        .padding(.bottom)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Hamburger Menu in leading position
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showStatistics = true
                        } label: {
                            Label(String(localized: "settings.statistics", bundle: .main), systemImage: "chart.bar.fill")
                        }
                        
                        Divider()
                        
                        Button {
                            showArchiveManagement = true
                        } label: {
                            Label(String(localized: "home.archive.management", bundle: .main), systemImage: "archivebox")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    // Filament Garden Logo - spool with leaf
                    HStack(spacing: 4) {
                        Image("filament-garder-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        
                        Text("home.title", bundle: .main)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Settings Menu
                    Menu {
                        Button {
                            showDataMigration = true
                        } label: {
                            Label(String(localized: "migration.title", bundle: .main), systemImage: "arrow.left.arrow.right")
                        }
                        
                        Divider()
                        
                        Button {
                            showLanguagePicker = true
                        } label: {
                            Label(String(localized: "home.language", bundle: .main), systemImage: "globe")
                        }
                        
                        Divider()
                        
                        Button {
                            showProfile = true
                        } label: {
                            Label(String(localized: "home.profile", bundle: .main), systemImage: "person.circle")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddMaterial) {
                AddMaterialView()
            }
            .sheet(isPresented: $showLogUsage) {
                if let firstFilament = filaments.first {
                    TrackUsageView(filament: firstFilament)
                } else {
                    // Show empty state or create new filament
                    Text(String(localized: "home.no.filaments.available", bundle: .main))
                }
            }
            .sheet(item: $selectedGroup) { group in
                ColorMaterialStatsSheet(group: group)
            }
            .sheet(item: $groupToEdit) { group in
                NavigationStack {
                    GroupEditView(group: group)
                }
            }
            .sheet(isPresented: $showArchiveManagement) {
                ArchiveManagementView()
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView(languageManager: languageManager)
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsView()
            }
            .sheet(isPresented: $showDataMigration) {
                DataMigrationView()
            }
            .alert(String(localized: "detail.archive", bundle: .main), isPresented: $showArchiveAlert) {
                Button(String(localized: "cancel", bundle: .main), role: .cancel) {
                    groupToArchive = nil
                }
                Button(String(localized: "detail.archive", bundle: .main), role: .destructive) {
                    if let group = groupToArchive {
                        archiveGroup(group)
                        groupToArchive = nil
                    }
                }
            } message: {
                if let group = groupToArchive {
                    let spoolText = group.totalCount > 1 ? String(localized: "home.spools", bundle: .main) : String(localized: "home.spool", bundle: .main)
                    Text(String(format: String(localized: "home.archive.confirm", bundle: .main), group.totalCount, spoolText, group.colorName, group.material))
                }
            }
        }
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        HStack(spacing: 12) {
            // Total Stock Card
            SummaryCard(
                icon: {
                    // Stacked Filament Spools Icon
                    Image("index.stacked-spools")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                },
                title: String(localized: "home.total.stock", bundle: .main),
                value: "\(totalStock)",
                backgroundColor: Color(hex: "#7FD4B0")
            )
            
            // Total Usage Card
            SummaryCard(
                icon: {
                    // 3D Printer Icon
                    Image("index.printer-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                },
                title: String(localized: "home.total.usage", bundle: .main),
                value: formatUsage(totalUsage),
                backgroundColor: Color(hex: "#8BC5D9")
            )
            
            // Most Used Card
            SummaryCard(
                icon: {
                    // Filament Spool with center circle Icon
                    Image("index.spool-with-circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                },
                title: String(localized: "home.most.used", bundle: .main),
                valueView: {
                    if let mostUsed = mostUsedColor {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: mostUsed.colorHex))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                            Text(mostUsed.material)
                                .font(.system(size: 18, weight: .bold))
                        }
                    } else {
                        Text(String(localized: "home.na", bundle: .main))
                            .font(.system(size: 18, weight: .bold))
                    }
                },
                backgroundColor: Color(hex: "#B88A5A")
            )
        }
    }
    
    // MARK: - Current Inventory Section
    private var currentInventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home.current.inventory", bundle: .main))
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            // Material Filter - Horizontal Scrollable Chips
            if !availableMaterials.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All Materials option
                        FilterChip(
                            title: String(localized: "home.all", bundle: .main),
                            isSelected: selectedMaterialFilter == nil
                        ) {
                            selectedMaterialFilter = nil
                        }
                        
                        // Material type options
                        ForEach(availableMaterials, id: \.self) { material in
                            FilterChip(
                                title: material,
                                isSelected: selectedMaterialFilter == material
                            ) {
                                selectedMaterialFilter = material
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            if groupedFilaments.isEmpty {
                EmptyInventoryView()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(groupedFilaments) { group in
                            GroupedInventoryRow(
                                group: group,
                                onTap: { selectedGroup = group },
                                onArchive: {
                                    groupToArchive = group
                                    showArchiveAlert = true
                                }
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Add Material Button
            ActionButton(
                icon: {
                    // TODO: Plus Sign Icon
                    Image(systemName: "plus.circle")
                        .font(.title3)
                },
                title: String(localized: "home.add.material", bundle: .main),
                backgroundColor: Color(hex: "#7FD4B0")
            ) {
                showAddMaterial = true
            }
            
            // Log Usage Button
            ActionButton(
                icon: {
                    // TODO: Log Usage Icon - Checklist/Edit
                    Image(systemName: "doc")
                        .font(.title3)
                },
                title: String(localized: "home.log.usage", bundle: .main),
                backgroundColor: Color(hex: "#8BC5D9")
            ) {
                showLogUsage = true
            }
        }
    }
}

// MARK: - Summary Card
struct SummaryCard<Icon: View, ValueView: View>: View {
    let icon: () -> Icon
    let title: String
    @ViewBuilder let valueView: () -> ValueView
    let backgroundColor: Color
    
    init(icon: @escaping () -> Icon, title: String, value: String, backgroundColor: Color) where ValueView == Text {
        self.icon = icon
        self.title = title
        self.valueView = { Text(value).font(.system(size: 18, weight: .bold)) }
        self.backgroundColor = backgroundColor
    }
    
    init(icon: @escaping () -> Icon, title: String, @ViewBuilder valueView: @escaping () -> ValueView, backgroundColor: Color) {
        self.icon = icon
        self.title = title
        self.valueView = valueView
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon centered
            HStack {
                Spacer()
                icon()
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            valueView()
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 80)
        .padding()
        .background(backgroundColor.opacity(0.85))
        .cornerRadius(16)
    }
}

// MARK: - Inventory Item Row
struct InventoryItemRow: View {
    let filament: Filament
    
    var body: some View {
        HStack(spacing: 12) {
            // Color Indicator
            // TODO: Color Circle Icons (White, Blue, Brown/Wood, Black, Light Grey/Transparent)
            Circle()
                .fill(Color(hex: filament.colorHex))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            
            // Material Name
            Text("\(filament.colorName) \(filament.material)")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Weight
            Text(String(format: "%.1f kg", filament.remainingWeight / 1000.0))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress Circle
            // TODO: Progress Circle Icons (80%, 50%, 70%, 20%, 30%)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: CGFloat(filament.remainingPercentage / 100.0))
                    .stroke(
                        progressColor(for: filament.remainingPercentage),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(filament.remainingPercentage))%")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 70 {
            return Color(hex: "#A8E6CF")
        } else if percentage >= 50 {
            return Color(hex: "#B8E0F0")
        } else if percentage >= 30 {
            return Color(hex: "#D4A574")
        } else {
            return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Grouped Inventory Row
struct GroupedInventoryRow: View {
    let group: FilamentGroup
    let onTap: () -> Void
    let onArchive: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // Color Indicator
                Circle()
                    .fill(Color(hex: group.colorHex))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                
                // Color Name and Material
                Text("\(group.colorName) \(group.material)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Total Weight
                Text(String(format: "%.1f kg", group.totalRemaining / 1000.0))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(group.averagePercentage / 100.0))
                        .stroke(
                            progressColor(for: group.averagePercentage),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(group.averagePercentage))%")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                let spoolText = group.totalCount > 1 ? String(localized: "home.spools", bundle: .main) : String(localized: "home.spool", bundle: .main)
                Text("\(group.totalCount) \(spoolText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 28)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onArchive) {
                Label(String(localized: "detail.archive", bundle: .main), systemImage: "archivebox")
            }
        }
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 70 {
            return Color(hex: "#A8E6CF")
        } else if percentage >= 50 {
            return Color(hex: "#B8E0F0")
        } else if percentage >= 30 {
            return Color(hex: "#D4A574")
        } else {
            return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Action Button
struct ActionButton<Icon: View>: View {
    let icon: () -> Icon
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon()
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor.opacity(0.85))
            .cornerRadius(12)
        }
    }
}

// MARK: - Empty Inventory View
struct EmptyInventoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text(String(localized: "home.no.materials", bundle: .main))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Color Material Stats Sheet
struct ColorMaterialStatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let group: FilamentGroup
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching home page
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#EBEBE0"), // Warm beige at top-left
                        Color(hex: "#E0EBF0")  // Cool beige with light blue hint at bottom-right
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with color indicator
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: group.colorHex))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Text("\(group.colorName) \(group.material)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.top)
                        
                        // Stats Cards
                        HStack(spacing: 12) {
                            GroupStatsCard(
                                title: String(localized: "home.group.stats.spools", bundle: .main),
                                value: "\(group.totalCount)",
                                icon: "cylinder.split.1x2",
                                color: Color(hex: "#D97A6A")
                            )
                            
                            GroupStatsCard(
                                title: String(localized: "home.group.stats.remaining", bundle: .main),
                                value: String(format: "%.1f kg", group.totalRemaining / 1000.0 ),
                                icon: "scalemass",
                                color: Color(hex: "#8A7BC4")
                            )
                            
                            GroupStatsCard(
                                title: String(localized: "home.group.stats.used", bundle: .main),
                                value: String(format: "%.0f g", group.totalUsed),
                                icon: "arrow.down.circle",
                                color: Color(hex: "#6B9563")
                            )
                        }
                        .padding(.horizontal)
                        
                        // Usage Trend Chart
                        if !group.allLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(localized: "home.usage.trend", bundle: .main))
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                GroupUsageChart(logs: group.allLogs)
                                    .frame(height: 180)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // Filament List
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "home.spool.details", bundle: .main))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            GroupFilamentList(filaments: group.filaments)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Usage History
                        if !group.allLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(localized: "home.usage.history", bundle: .main))
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                GroupUsageHistory(logs: group.allLogs)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.large, .medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Group Stats Card
struct GroupStatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.black)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.85))
        .cornerRadius(12)
    }
}

// MARK: - Group Usage Chart
struct GroupUsageChart: View {
    let logs: [UsageLog]
    
    var body: some View {
        Chart {
            ForEach(dailyUsage, id: \.date) { data in
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Usage", data.amount)
                )
                .foregroundStyle(Color(hex: "#8BC5D9").gradient)
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text("\(Int(amount))g")
                    }
                }
            }
        }
    }
    
    private var dailyUsage: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.date)
        }
        
        return grouped.map { (date, logs) in
            (date: date, amount: logs.reduce(0.0) { $0 + $1.amount })
        }
        .sorted { $0.date < $1.date }
        .suffix(14) // Show last 14 days
        .map { $0 }
    }
}

// MARK: - Group Filament List
struct GroupFilamentList: View {
    let filaments: [Filament]
    @State private var selectedFilament: Filament?
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(filaments) { filament in
                HStack(spacing: 12) {
                    BrandLogoView(brand: filament.brand)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(filament.brand.isEmpty ? String(localized: "home.unknown.brand", bundle: .main) : filament.brand)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(Int(filament.remainingWeight))g / \(Int(filament.initialWeight))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(filament.remainingPercentage / 100.0))
                            .stroke(
                                progressColor(for: filament.remainingPercentage),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(filament.remainingPercentage))%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedFilament = filament
                }
                
                if filament.id != filaments.last?.id {
                    Divider()
                }
            }
        }
        .sheet(item: $selectedFilament) { filament in
            NavigationStack {
                DetailView(filament: filament)
            }
        }
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 70 {
            return Color(hex: "#A8E6CF")
        } else if percentage >= 50 {
            return Color(hex: "#B8E0F0")
        } else if percentage >= 30 {
            return Color(hex: "#D4A574")
        } else {
            return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Group Usage History
struct GroupUsageHistory: View {
    let logs: [UsageLog]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(sortedLogs.prefix(10)) { log in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.note ?? log.usageType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 4) {
                            Text(log.date, style: .date)
                            Text("·")
                            Text(log.usageType.displayName)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("-\(Int(log.amount))g")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 8)
                
                if log.id != sortedLogs.prefix(10).last?.id {
                    Divider()
                }
            }
            
            if sortedLogs.count > 10 {
                Text(String(format: String(localized: "home.more.records", bundle: .main), sortedLogs.count - 10))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
    
    private var sortedLogs: [UsageLog] {
        logs.sorted { $0.date > $1.date }
    }
}

// MARK: - Group Edit View
struct GroupEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let group: FilamentGroup
    
    @State private var filamentToEdit: Filament?
    @State private var filamentToArchive: Filament?
    @State private var showArchiveFilamentAlert = false
    @State private var displayedFilaments: [Filament] = []
    @State private var isInitialized = false
    
    // Initialize displayed filaments only once on appear
    private func initializeDisplayedFilaments() {
        guard !isInitialized else { return }
        // Copy and sort filaments from the group (stable initial list)
        displayedFilaments = group.filaments.sorted { $0.remainingWeight > $1.remainingWeight }
        isInitialized = true
    }
    
    // Remove a filament from the displayed list (after confirmed archiving)
    private func removeFromDisplayedList(_ filament: Filament) {
        displayedFilaments.removeAll { $0.id == filament.id }
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching home page
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#EBEBE0"), // Warm beige at top-left
                    Color(hex: "#E0EBF0")  // Cool beige with light blue hint at bottom-right
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            List {
                Section {
                    let spoolText = displayedFilaments.count > 1 ? String(localized: "home.spools", bundle: .main) : String(localized: "home.spool", bundle: .main)
                    Text(String(format: String(localized: "home.spools.in.group", bundle: .main), displayedFilaments.count, spoolText))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }
                
                if displayedFilaments.isEmpty {
                    Section {
                        Text(String(localized: "home.no.spools.remaining", bundle: .main))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(displayedFilaments) { filament in
                            GroupEditRow(filament: filament)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    filamentToEdit = filament
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        filamentToArchive = filament
                                        showArchiveFilamentAlert = true
                                    } label: {
                                        Label(String(localized: "detail.archive", bundle: .main), systemImage: "archivebox")
                                    }
                                }
                                .listRowBackground(Color(.systemBackground).opacity(0.9))
                        }
                    } header: {
                        Text(String(localized: "home.spools", bundle: .main))
                    } footer: {
                        Text(String(localized: "home.swipe.to.archive", bundle: .main))
                            .font(.caption)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("\(group.colorName) \(group.material)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "archive.done", bundle: .main)) {
                    dismiss()
                }
            }
        }
        .onAppear {
            initializeDisplayedFilaments()
        }
        .sheet(item: $filamentToEdit) { filament in
            AddMaterialView(filament: filament)
        }
        .alert(String(localized: "detail.archive", bundle: .main), isPresented: $showArchiveFilamentAlert) {
            Button(String(localized: "cancel", bundle: .main), role: .cancel) {
                filamentToArchive = nil
            }
            Button(String(localized: "detail.archive", bundle: .main), role: .destructive) {
                if let filament = filamentToArchive {
                    archiveFilament(filament)
                    filamentToArchive = nil
                }
            }
        } message: {
            if let filament = filamentToArchive {
                let brandText = filament.brand.isEmpty ? "" : filament.brand + " "
                Text(String(format: String(localized: "home.archive.spool.confirm", bundle: .main), brandText, filament.colorName, filament.material))
            }
        }
    }
    
    private func archiveFilament(_ filament: Filament) {
        // First remove from displayed list (immediate UI update)
        removeFromDisplayedList(filament)
        // Then archive
        filament.isArchived = true
        try? modelContext.save()
    }
}

// MARK: - Group Edit Row
struct GroupEditRow: View {
    let filament: Filament
    
    var body: some View {
        HStack(spacing: 12) {
            BrandLogoView(brand: filament.brand)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(filament.brand.isEmpty ? String(localized: "home.unknown.brand", bundle: .main) : filament.brand)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(filament.remainingWeight))g / \(Int(filament.initialWeight))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 28, height: 28)
                
                Circle()
                    .trim(from: 0, to: CGFloat(filament.remainingPercentage / 100.0))
                    .stroke(
                        progressColor(for: filament.remainingPercentage),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(filament.remainingPercentage))%")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 70 {
            return Color(hex: "#A8E6CF")
        } else if percentage >= 50 {
            return Color(hex: "#B8E0F0")
        } else if percentage >= 30 {
            return Color(hex: "#D4A574")
        } else {
            return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Brand Logo View
struct BrandLogoView: View {
    let brand: String
    
    private func brandLogoImageName(for brand: String) -> String {
        let trimmed = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let lowered = trimmed.lowercased()
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitizedScalars = lowered
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowedCharacters.contains($0) ? Character($0) : "-" }
        
        let sanitized = String(sanitizedScalars)
        return "brand-\(sanitized)"
    }
    
    private func logoUIImage(for brand: String) -> UIImage? {
        let imageName = brandLogoImageName(for: brand)
        guard !imageName.isEmpty else { return nil }
        return UIImage(named: imageName)
    }
    
    var body: some View {
        if let uiImage = logoUIImage(for: brand) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        } else {
            let displayText = brand.trimmingCharacters(in: .whitespacesAndNewlines)
            let letter = displayText.isEmpty ? "?" : String(displayText.prefix(1)).uppercased()
            
            ZStack {
                Circle()
                    .fill(Color(hex: "#6B9B7A").opacity(0.2))
                Text(letter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#6B9B7A"))
            }
            .frame(width: 24, height: 24)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
