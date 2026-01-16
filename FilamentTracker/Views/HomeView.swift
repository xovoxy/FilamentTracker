//
//  HomeView.swift
//  FilamentTracker
//
//  Home page view matching the new design
//

import SwiftUI
import SwiftData
import Charts

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
    
    @State private var showAddMaterial = false
    @State private var showLogUsage = false
    @State private var showMenu = false
    @State private var showSettings = false
    @State private var showProfile = false
    @State private var selectedGroup: FilamentGroup?
    @State private var groupToEdit: FilamentGroup?
    @State private var groupToDelete: FilamentGroup?
    @State private var showDeleteAlert = false
    
    // Calculate total stock in kg
    var totalStock: Double {
        filaments.reduce(0) { $0 + $1.remainingWeight } / 1000.0
    }
    
    // Calculate total usage in meters (approximate conversion)
    var totalUsage: Double {
        let totalGrams = usageLogs.reduce(0) { $0 + $1.amount }
        // Approximate conversion: 1kg PLA ≈ 330m (for 1.75mm diameter)
        return (totalGrams / 1000.0) * 330.0
    }
    
    // Find most used color
    var mostUsedColor: (color: String, percentage: Double)? {
        guard !filaments.isEmpty else { return nil }
        
        let colorCounts = Dictionary(grouping: filaments, by: { $0.colorName })
            .mapValues { $0.count }
        
        guard let mostUsed = colorCounts.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        let percentage = Double(mostUsed.value) / Double(filaments.count) * 100.0
        return (mostUsed.key, percentage)
    }
    
    // Group filaments by color and material
    var groupedFilaments: [FilamentGroup] {
        let grouped = Dictionary(grouping: filaments) { filament in
            "\(filament.colorName)-\(filament.material)"
        }
        
        return grouped.compactMap { (_, filaments) -> FilamentGroup? in
            guard let first = filaments.first else { return nil }
            // Sort filaments by remaining weight (descending)
            let sortedFilaments = filaments.sorted { $0.remainingWeight > $1.remainingWeight }
            return FilamentGroup(
                colorName: first.colorName,
                colorHex: first.colorHex,
                material: first.material,
                filaments: sortedFilaments
            )
        }.sorted { $0.totalRemaining > $1.totalRemaining }
    }
    
    // Delete all filaments in a group
    private func deleteGroup(_ group: FilamentGroup) {
        for filament in group.filaments {
            modelContext.delete(filament)
        }
        try? modelContext.save()
        groupToDelete = nil
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
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary Cards Section
                            summaryCardsSection
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            // Current Inventory Section
                            currentInventorySection
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                        }
                    }
                    
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
                
                ToolbarItem(placement: .principal) {
                    // Filament Garden Logo - spool with leaf
                    HStack(spacing: 4) {
                        Image("filament-garder-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        
                        Text("Filament Garden")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // TODO: Settings Gear Icon
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    // TODO: User Profile Icon
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle")
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
                    Text("No filaments available")
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
            .alert("Delete Filaments", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    groupToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let group = groupToDelete {
                        deleteGroup(group)
                        groupToDelete = nil
                    }
                }
            } message: {
                if let group = groupToDelete {
                    Text("Are you sure you want to delete \(group.totalCount) spool\(group.totalCount > 1 ? "s" : "") of \(group.colorName) \(group.material)?")
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
                title: "Total Stock",
                value: String(format: "%.1f kg", totalStock),
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
                title: "Total Usage",
                value: String(format: "%.0f m", totalUsage),
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
                title: "Most Used",
                value: mostUsedColor.map { $0.color } ?? "N/A",
                backgroundColor: Color(hex: "#B88A5A")
            )
        }
    }
    
    // MARK: - Current Inventory Section
    private var currentInventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Inventory")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            if groupedFilaments.isEmpty {
                EmptyInventoryView()
            } else {
                List {
                    ForEach(groupedFilaments) { group in
                        GroupedInventoryRow(
                            group: group,
                            onTap: { selectedGroup = group },
                            onEdit: { groupToEdit = group },
                            onDelete: {
                                groupToDelete = group
                                showDeleteAlert = true
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: CGFloat(min(groupedFilaments.count, 3)) * 90)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Add Material Button
            ActionButton(
                icon: {
                    // TODO: Plus Sign Icon
                    Image(systemName: "plus")
                        .font(.title3)
                },
                title: "Add Material",
                backgroundColor: Color(hex: "#7FD4B0")
            ) {
                showAddMaterial = true
            }
            
            // Log Usage Button
            ActionButton(
                icon: {
                    // TODO: Log Usage Icon - Checklist/Edit
                    Image(systemName: "checklist")
                        .font(.title3)
                },
                title: "Log Usage",
                backgroundColor: Color(hex: "#8BC5D9")
            ) {
                showLogUsage = true
            }
        }
    }
}

// MARK: - Summary Card
struct SummaryCard<Icon: View>: View {
    let icon: () -> Icon
    let title: String
    let value: String
    let backgroundColor: Color
    
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
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
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
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // Color Indicator
                Circle()
                    .fill(Color(hex: group.colorHex))
                    .frame(width: 16, height: 16)
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
                Text("\(group.totalCount) spool\(group.totalCount > 1 ? "s" : "")")
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
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
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
            Text("No materials yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity)
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
                                title: "Spools",
                                value: "\(group.totalCount)",
                                icon: "cylinder.split.1x2",
                                color: Color(hex: "#F7B2A7")
                            )
                            
                            GroupStatsCard(
                                title: "Remaining",
                                value: String(format: "%.1f kg", group.totalRemaining / 1000.0 ),
                                icon: "scalemass",
                                color: Color(hex: "#C8BFE7")
                            )
                            
                            GroupStatsCard(
                                title: "Used",
                                value: String(format: "%.0f g", group.totalUsed),
                                icon: "arrow.down.circle",
                                color: Color(hex: "#A0C49D")
                            )
                        }
                        .padding(.horizontal)
                        
                        // Usage Trend Chart
                        if !group.allLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Usage Trend")
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
                            Text("Spool Details")
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
                                Text("Usage History")
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
                .foregroundColor(color)
            
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
                    Circle()
                        .fill(Color(hex: filament.colorHex))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(filament.brand.isEmpty ? "Unknown Brand" : filament.brand)
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
                Text("+ \(sortedLogs.count - 10) more records")
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
    @State private var filamentToDelete: Filament?
    @State private var showDeleteFilamentAlert = false
    @State private var displayedFilaments: [Filament] = []
    @State private var isInitialized = false
    
    // Initialize displayed filaments only once on appear
    private func initializeDisplayedFilaments() {
        guard !isInitialized else { return }
        // Copy and sort filaments from the group (stable initial list)
        displayedFilaments = group.filaments.sorted { $0.remainingWeight > $1.remainingWeight }
        isInitialized = true
    }
    
    // Remove a filament from the displayed list (after confirmed deletion)
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
                    Text("\(displayedFilaments.count) spool\(displayedFilaments.count > 1 ? "s" : "") in this group")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }
                
                if displayedFilaments.isEmpty {
                    Section {
                        Text("No spools remaining")
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
                                        filamentToDelete = filament
                                        showDeleteFilamentAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(Color(.systemBackground).opacity(0.9))
                        }
                    } header: {
                        Text("Spools")
                    } footer: {
                        Text("Swipe left on any spool to delete")
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
                Button("Done") {
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
        .alert("Delete Spool", isPresented: $showDeleteFilamentAlert) {
            Button("Cancel", role: .cancel) {
                filamentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let filament = filamentToDelete {
                    deleteFilament(filament)
                    filamentToDelete = nil
                }
            }
        } message: {
            if let filament = filamentToDelete {
                Text("Are you sure you want to delete this \(filament.brand.isEmpty ? "" : filament.brand + " ")\(filament.colorName) \(filament.material) spool?")
            }
        }
    }
    
    private func deleteFilament(_ filament: Filament) {
        // First remove from displayed list (immediate UI update)
        removeFromDisplayedList(filament)
        // Then delete from database
        modelContext.delete(filament)
        try? modelContext.save()
    }
}

// MARK: - Group Edit Row
struct GroupEditRow: View {
    let filament: Filament
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: filament.colorHex))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(filament.brand.isEmpty ? "Unknown Brand" : filament.brand)
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

#Preview {
    HomeView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
