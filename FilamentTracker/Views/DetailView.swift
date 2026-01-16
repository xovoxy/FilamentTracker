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
                
                // Detailed Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Details")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        // Remaining Weight
                        DetailInfoRow(
                            icon: "scalemass",
                            title: "Remaining Weight",
                            value: String(format: "%.1f g", filament.remainingWeight)
                        )
                        
                        // Initial Weight
                        DetailInfoRow(
                            icon: "cube.box",
                            title: "Initial Weight",
                            value: String(format: "%.1f g", filament.initialWeight)
                        )
                        
                        // Price
                        if let price = filament.price {
                            DetailInfoRow(
                                icon: "dollarsign.circle",
                                title: "Price",
                                value: formatPrice(price)
                            )
                        }
                        
                        // Notes
                        if let notes = filament.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.teal)
                                        .frame(width: 20)
                                    Text("Notes")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 28)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Additional Info
                        VStack(alignment: .leading, spacing: 8) {
                            if let diameter = Optional(filament.diameter), diameter > 0 {
                                DetailInfoRow(
                                    icon: "circle.dotted",
                                    title: "Diameter",
                                    value: String(format: "%.2f mm", diameter)
                                )
                            }
                            
                            if let emptySpoolWeight = filament.emptySpoolWeight {
                                DetailInfoRow(
                                    icon: "scalemass.fill",
                                    title: "Empty Spool Weight",
                                    value: String(format: "%.1f g", emptySpoolWeight)
                                )
                            }
                            
                            if let density = filament.density {
                                DetailInfoRow(
                                    icon: "drop.fill",
                                    title: "Density",
                                    value: String(format: "%.2f g/cm³", density)
                                )
                            }
                            
                            DetailInfoRow(
                                icon: "calendar",
                                title: "Purchase Date",
                                value: filament.purchaseDate.formatted(date: .abbreviated, time: .omitted)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
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
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
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

struct DetailInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.teal)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
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
