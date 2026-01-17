//
//  RemindersView.swift
//  FilamentTracker
//
//  Reminders and alerts view
//

import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Filament> { !$0.isArchived }) private var filaments: [Filament]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.teal)
                        Text(String(localized: "reminders.title", bundle: .main))
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(reminders) { reminder in
                            ReminderCard(reminder: reminder)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button {
                        // Manage alerts action
                    } label: {
                        Text(String(localized: "reminders.manage.alerts", bundle: .main))
                            .font(.subheadline)
                            .foregroundColor(.teal)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "reminders.title", bundle: .main))
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var reminders: [Reminder] {
        var result: [Reminder] = []
        
        // Check for low stock
        let lowStockFilaments = filaments.filter { $0.isLowStock }
        for filament in lowStockFilaments {
            if let daysUntilEmpty = daysUntilEmpty(for: filament) {
                result.append(Reminder(
                    id: UUID(),
                    title: String(format: String(localized: "reminders.order.more", bundle: .main), filament.material),
                    subtitle: daysUntilEmpty == 0 ? String(localized: "reminders.today", bundle: .main) : String(format: String(localized: "reminders.days", bundle: .main), daysUntilEmpty),
                    type: .lowStock,
                    color: .blue
                ))
            }
        }
        
        // Check for drying needed (placeholder - would need humidity tracking)
        result.append(Reminder(
            id: UUID(),
            title: String(localized: "reminders.drying.needed", bundle: .main),
            subtitle: String(localized: "reminders.today", bundle: .main),
            type: .drying,
            color: .orange
        ))
        
        // Check print bed
        result.append(Reminder(
            id: UUID(),
            title: String(localized: "reminders.check.bed", bundle: .main),
            subtitle: String(localized: "reminders.tomorrow", bundle: .main),
            type: .maintenance,
            color: Color(hex: "#F5DEB3")
        ))
        
        return result
    }
    
    private func daysUntilEmpty(for filament: Filament) -> Int? {
        guard !filament.logs.isEmpty else { return nil }
        
        let sortedLogs = filament.logs.sorted { $0.date > $1.date }
        let recentUsage = sortedLogs.prefix(7).reduce(0.0) { $0 + $1.amount }
        let dailyAverage = recentUsage / 7.0
        
        guard dailyAverage > 0 else { return nil }
        let daysRemaining = Int(filament.remainingWeight / dailyAverage)
        return daysRemaining
    }
}

struct Reminder: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let type: ReminderType
    let color: Color
}

enum ReminderType {
    case lowStock
    case drying
    case maintenance
}

struct ReminderCard: View {
    let reminder: Reminder
    
    var icon: String {
        switch reminder.type {
        case .lowStock:
            return "bell.fill"
        case .drying:
            return "drop.fill"
        case .maintenance:
            return "printer.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(reminder.color)
                .font(.title3)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                
                Text(reminder.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(reminder.color.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    RemindersView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
