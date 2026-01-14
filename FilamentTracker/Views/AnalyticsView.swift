//
//  AnalyticsView.swift
//  FilamentTracker
//
//  Analytics and usage tracking view
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Filament> { !$0.isArchived }) private var filaments: [Filament]
    @Query(sort: \UsageLog.date, order: .reverse) private var allLogs: [UsageLog]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Track Usage Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.teal)
                            Text("Track Usage")
                                .font(.headline)
                            Spacer()
                            CircularProgressView(percentage: overallUsagePercentage)
                        }
                        .padding(.horizontal)
                        
                        UsageChartView(logs: recentLogs)
                            .frame(height: 200)
                            .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Analytics Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.teal)
                            Text("Analytics")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 24) {
                            MaterialDistributionChart(filaments: filaments)
                                .frame(width: 200, height: 200)
                            
                            MaterialLegend(filaments: filaments)
                        }
                        .padding()
                        
                        Text("Summary analyzed material type: PLA, ABS, PETG management")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var recentLogs: [UsageLog] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allLogs.filter { $0.date >= weekAgo }
    }
    
    private var overallUsagePercentage: Double {
        guard !filaments.isEmpty else { return 0 }
        let totalUsed = filaments.reduce(0.0) { $0 + ($1.initialWeight - $1.remainingWeight) }
        let totalInitial = filaments.reduce(0.0) { $0 + $1.initialWeight }
        guard totalInitial > 0 else { return 0 }
        return (totalUsed / totalInitial) * 100
    }
}

struct CircularProgressView: View {
    let percentage: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 50, height: 50)
            
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(Color.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct UsageChartView: View {
    let logs: [UsageLog]
    
    var body: some View {
        Chart {
            ForEach(groupedLogs, id: \.day) { data in
                LineMark(
                    x: .value("Day", data.day),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(Color.teal)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Day", data.day),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.3), Color.teal.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
    
    private var groupedLogs: [(day: Date, amount: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.date)
        }
        
        return grouped.map { (day, logs) in
            (day: day, amount: logs.reduce(0.0) { $0 + $1.amount })
        }.sorted { $0.day < $1.day }
    }
}

struct MaterialDistributionChart: View {
    let filaments: [Filament]
    
    var body: some View {
        Chart {
            ForEach(materialData, id: \.material) { data in
                SectorMark(
                    angle: .value("Percentage", data.percentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(colorForMaterial(data.material))
            }
        }
    }
    
    private var materialData: [(material: String, percentage: Double)] {
        let total = filaments.reduce(0.0) { $0 + $1.remainingWeight }
        guard total > 0 else { return [] }
        
        let grouped = Dictionary(grouping: filaments) { $0.material }
        return grouped.map { (material, filaments) in
            let weight = filaments.reduce(0.0) { $0 + $1.remainingWeight }
            return (material: material, percentage: (weight / total) * 100)
        }
    }
    
    private func colorForMaterial(_ material: String) -> Color {
        switch material.uppercased() {
        case "PLA": return Color.teal
        case "ABS": return Color.brown
        case "PETG": return Color(hex: "#F5DEB3")
        default: return Color.gray
        }
    }
}

struct MaterialLegend: View {
    let filaments: [Filament]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(materialStats, id: \.material) { stat in
                HStack(spacing: 8) {
                    Circle()
                        .fill(colorForMaterial(stat.material))
                        .frame(width: 12, height: 12)
                    
                    Text("\(stat.material) \(Int(stat.percentage))%")
                        .font(.subheadline)
                }
            }
        }
    }
    
    private var materialStats: [(material: String, percentage: Double)] {
        let total = filaments.reduce(0.0) { $0 + $1.remainingWeight }
        guard total > 0 else { return [] }
        
        let grouped = Dictionary(grouping: filaments) { $0.material }
        return grouped.map { (material, filaments) in
            let weight = filaments.reduce(0.0) { $0 + $1.remainingWeight }
            return (material: material, percentage: (weight / total) * 100)
        }.sorted { $0.percentage > $1.percentage }
    }
    
    private func colorForMaterial(_ material: String) -> Color {
        switch material.uppercased() {
        case "PLA": return Color.teal
        case "ABS": return Color.brown
        case "PETG": return Color(hex: "#F5DEB3")
        default: return Color.gray
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
