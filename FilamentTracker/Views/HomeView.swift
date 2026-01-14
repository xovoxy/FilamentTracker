//
//  HomeView.swift
//  FilamentTracker
//
//  Home page view matching the new design
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Filament> { !$0.isArchived }) private var filaments: [Filament]
    @Query private var usageLogs: [UsageLog]
    
    @State private var showAddMaterial = false
    @State private var showLogUsage = false
    @State private var showMenu = false
    @State private var showSettings = false
    @State private var showProfile = false
    
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
            
            if filaments.isEmpty {
                EmptyInventoryView()
            } else {
                VStack(spacing: 8) {
                    ForEach(filaments.prefix(5)) { filament in
                        InventoryItemRow(filament: filament)
                    }
                }
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

#Preview {
    HomeView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
