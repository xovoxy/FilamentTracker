//
//  DetailView.swift
//  FilamentTracker
//
//  Detailed view for a single filament spool
//

import SwiftUI
import SwiftData
import Charts

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let filament: Filament
    @State private var showEditSheet = false
    @State private var showLogUsageSheet = false
    @State private var showArchiveAlert = false
    
    // Calculate total used weight in grams
    private var totalUsedWeight: Double {
        filament.logs.reduce(0) { $0 + $1.amount }
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Filament Summary Card
                    filamentSummaryCard
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Key Metrics Section
                    keyMetricsSection
                        .padding(.horizontal)
                    
                    // Usage Trend Chart
                    if !filament.logs.isEmpty {
                        usageTrendSection
                            .padding(.horizontal)
                    }
                    
                    // Usage History
                    if !filament.logs.isEmpty {
                        usageHistorySection
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Material Detail")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        showLogUsageSheet = true
                    } label: {
                        Label("Log Usage", systemImage: "plus.circle")
                    }
                    
                    Button(role: .destructive) {
                        showArchiveAlert = true
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                AddMaterialView(filament: filament)
            }
        }
        .sheet(isPresented: $showLogUsageSheet) {
            TrackUsageView(filament: filament)
        }
        .alert("Archive Filament", isPresented: $showArchiveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                archiveFilament()
            }
        } message: {
            Text("Are you sure you want to archive this \(filament.brand.isEmpty ? "" : filament.brand + " ")\(filament.colorName) \(filament.material) spool? It will be hidden from the main view but can be restored later.")
        }
    }
    
    private func archiveFilament() {
        filament.isArchived = true
        try? modelContext.save()
        dismiss()
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
    
    // MARK: - Filament Summary Card
    private var filamentSummaryCard: some View {
        HStack(spacing: 16) {
            // Color Swatch
            Circle()
                .fill(Color(hex: filament.colorHex))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Filament Info
            VStack(alignment: .leading, spacing: 8) {
                Text("\(filament.colorName) \(filament.material)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "Material Type:", value: filament.material)
                    
                    InfoRow(
                        label: "Brand:",
                        value: filament.brand.isEmpty ? "Unknown" : filament.brand
                    )
                    
                    InfoRow(
                        label: "Diameter:",
                        value: String(format: "%.2f mm", filament.diameter)
                    )
                    
                    if let notes = filament.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notes:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 2)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Key Metrics Section
    private var keyMetricsSection: some View {
        HStack(spacing: 12) {
            // Stock Card
            MetricCard(
                icon: "cylinder.split.1x2",
                title: "Stock",
                value: String(format: "%.1f kg", filament.remainingWeight / 1000.0),
                color: Color(hex: "#D4A574")
            )
            
            // Usage Rate Card
            MetricCard(
                icon: "percent",
                title: "Usage Rate",
                value: String(format: "%.0f%%", 100 - filament.remainingPercentage),
                color: Color(hex: "#A0C49D")
            )
            
            // Price Card
            MetricCard(
                icon: "dollarsign.circle",
                title: "Price",
                value: filament.price != nil ? formatPrice(filament.price!) : "N/A",
                color: Color(hex: "#8BC5D9")
            )
        }
    }
    
    // MARK: - Usage Trend Section
    private var usageTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Trend")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            UsageTrendChart(filament: filament)
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Usage History Section
    private var usageHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage History")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(sortedLogs.prefix(10)) { log in
                    UsageHistoryRow(log: log, filament: filament)
                }
            }
        }
    }
    
    private var sortedLogs: [UsageLog] {
        filament.logs.sorted { $0.date > $1.date }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(height: 32)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Usage Trend Chart
struct UsageTrendChart: View {
    let filament: Filament
    
    var body: some View {
        Chart {
            ForEach(dailyUsage, id: \.date) { data in
                LineMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Usage", data.amount)
                )
                .foregroundStyle(Color(hex: "#A0C49D"))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(Color(hex: "#A0C49D"))
                        .frame(width: 8, height: 8)
                }
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
        let grouped = Dictionary(grouping: filament.logs) { log in
            calendar.startOfDay(for: log.date)
        }
        
        return grouped.map { (date, logs) in
            let dayUsage = logs.reduce(0.0) { $0 + $1.amount }
            return (date: date, amount: dayUsage)
        }
        .sorted { $0.date < $1.date }
        .suffix(14) // Show last 14 days
        .map { $0 }
    }
}

// MARK: - Usage History Row
struct UsageHistoryRow: View {
    let log: UsageLog
    let filament: Filament
    
    // Get icon based on usage type or note
    private var iconName: String {
        switch log.usageType {
        case .print:
            return "printer.fill"
        case .failedPrint:
            return "exclamationmark.triangle.fill"
        case .calibration:
            return "gearshape.fill"
        case .manualAdjustment:
            return "hand.point.up.left.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.teal)
                .frame(width: 32, height: 32)
                .background(Color.teal.opacity(0.1))
                .cornerRadius(8)
            
            // Date and Project Name
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(log.note ?? log.usageType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Weight
            Text(String(format: "%.0f g", log.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        DetailView(filament: Filament(
            brand: "Prusament",
            material: "PLA",
            colorName: "Olive Green",
            colorHex: "#808000",
            initialWeight: 1000,
            remainingWeight: 750
        ))
    }
    .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
