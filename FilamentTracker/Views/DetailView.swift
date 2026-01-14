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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with color representation
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color(hex: filament.colorHex))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        Text(filament.brand)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(filament.material) • \(filament.colorName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                // Stats
                HStack(spacing: 32) {
                    StatItem(
                        title: "Remaining",
                        value: "\(Int(filament.remainingPercentage))%",
                        icon: "gauge"
                    )
                    
                    StatItem(
                        title: "Days",
                        value: "\(filament.daysSincePurchase)",
                        icon: "calendar"
                    )
                    
                    StatItem(
                        title: "Prints",
                        value: "\(filament.logs.count)",
                        icon: "printer"
                    )
                }
                .padding()
                
                // Usage chart
                if !filament.logs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Usage Over Time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        UsageHistoryChart(filament: filament)
                            .frame(height: 200)
                            .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
                
                // History
                if !filament.logs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(filament.logs.sorted { $0.date > $1.date }) { log in
                            HistoryRow(log: log)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showLogUsageSheet = true
                    } label: {
                        Label("Log Usage", systemImage: "plus.circle")
                    }
                    
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        archiveFilament()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddMaterialView(filament: filament)
        }
        .sheet(isPresented: $showLogUsageSheet) {
            TrackUsageView(filament: filament)
        }
    }
    
    private func archiveFilament() {
        filament.isArchived = true
        dismiss()
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.teal)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct UsageHistoryChart: View {
    let filament: Filament
    
    var body: some View {
        Chart {
            ForEach(weightHistory, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.teal)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
    
    private var weightHistory: [(date: Date, weight: Double)] {
        guard !filament.logs.isEmpty else {
            return [(date: filament.purchaseDate, weight: filament.initialWeight)]
        }
        
        var history: [(date: Date, weight: Double)] = []
        var currentWeight = filament.initialWeight
        
        history.append((date: filament.purchaseDate, weight: currentWeight))
        
        for log in filament.logs.sorted(by: { $0.date < $1.date }) {
            currentWeight -= log.amount
            history.append((date: log.date, weight: max(0, currentWeight)))
        }
        
        return history
    }
}

struct HistoryRow: View {
    let log: UsageLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.note ?? "Usage")
                    .font(.headline)
                
                Text(log.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("-\(Int(log.amount))g")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(log.usageType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        DetailView(filament: Filament(
            brand: "Bambu Lab",
            material: "PLA",
            colorName: "Black",
            colorHex: "#000000",
            initialWeight: 1000,
            remainingWeight: 750
        ))
    }
    .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
