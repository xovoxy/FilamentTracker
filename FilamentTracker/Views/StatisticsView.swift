//
//  StatisticsView.swift
//  FilamentTracker
//
//  Statistics and analytics view for filament usage
//

import SwiftUI
import SwiftData
import Charts

enum TimeFilterType: String, CaseIterable {
    case month = "月"
    case year = "年"
    case all = "全部"
    
    var displayName: String {
        return self.rawValue
    }
}

enum ChartType: Identifiable {
    case usageTrend
    case costAnalysis
    case usageByMaterial
    
    var id: String {
        switch self {
        case .usageTrend: return "usageTrend"
        case .costAnalysis: return "costAnalysis"
        case .usageByMaterial: return "usageByMaterial"
        }
    }
}

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allFilaments: [Filament]
    @Query(sort: \UsageLog.date, order: .forward) private var allLogs: [UsageLog]
    
    @State private var selectedTimeFilter: TimeFilterType = .month
    @State private var selectedMonths: Int = 6 // Default to last 6 months
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showTimeFilterMenu = false
    @State private var selectedChartForFullscreen: ChartType?
    
    // Helper function to show chart in fullscreen with landscape orientation
    private func showChartFullscreen(_ chartType: ChartType) {
        // Lock to landscape before showing fullscreen
        AppDelegate.orientationLock = .landscape
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            }
        }
        UIViewController.attemptRotationToDeviceOrientation()
        
        // Small delay to allow orientation change to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectedChartForFullscreen = chartType
        }
    }
    
    // Computed property for filtered logs based on time filter
    private var filteredLogs: [UsageLog] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch selectedTimeFilter {
        case .month:
            // Last N months including current month
            // Start from the first day of (N-1) months ago to include current month
            // For example: 3 months = current month + 2 previous months
            let monthsAgo = selectedMonths - 1
            if let monthsAgoDate = calendar.date(byAdding: .month, value: -monthsAgo, to: now) {
                var components = calendar.dateComponents([.year, .month], from: monthsAgoDate)
                components.day = 1
                startDate = calendar.date(from: components) ?? now
            } else {
                // Fallback: start from current month
                var components = calendar.dateComponents([.year, .month], from: now)
                components.day = 1
                startDate = calendar.date(from: components) ?? now
            }
        case .year:
            // Selected year
            var components = DateComponents()
            components.year = selectedYear
            components.month = 1
            components.day = 1
            startDate = calendar.date(from: components) ?? now
            let endDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? now
            return allLogs.filter { log in
                log.date >= startDate && log.date < endDate
            }
        case .all:
            return allLogs
        }
        
        return allLogs.filter { log in
            log.date >= startDate
        }
    }
    
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
                        // Summary Cards Section
                        summaryCardsSection
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Charts Section
                        chartsSection
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        // Time filter type selection
                        Picker("时间维度", selection: $selectedTimeFilter) {
                            ForEach(TimeFilterType.allCases, id: \.self) { filterType in
                                Text(filterType.displayName).tag(filterType)
                            }
                        }
                        
                        Divider()
                        
                        // Month filter options
                        if selectedTimeFilter == .month {
                            ForEach([1, 3, 6, 12], id: \.self) { months in
                                Button {
                                    selectedMonths = months
                                } label: {
                                    HStack {
                                        Text("最近\(months)个月")
                                        if selectedMonths == months {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Year filter options
                        if selectedTimeFilter == .year {
                            let currentYear = Calendar.current.component(.year, from: Date())
                            ForEach((currentYear - 5)...currentYear, id: \.self) { year in
                                Button {
                                    selectedYear = year
                                } label: {
                                    HStack {
                                        Text("\(year)年")
                                        if selectedYear == year {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(timeFilterDisplayText)
                                .font(.subheadline)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "statistics.title", bundle: .main))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "archive.done", bundle: .main)) {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedChartForFullscreen) { chartType in
            ChartDetailView(
                chartType: chartType,
                filaments: allFilaments,
                logs: filteredLogs,
                timeFilter: selectedTimeFilter,
                selectedMonths: selectedMonths,
                selectedYear: selectedYear
            )
        }
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Total Spools Used Card
                StatisticsCard(
                    icon: {
                        Image("static.spools-used")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                    },
                    title: String(localized: "statistics.total.spools.used", bundle: .main),
                    value: "\(totalSpoolsUsed)",
                    backgroundColor: Color(hex: "#7FD4B0")
                )
                
                // Total Weight Used Card
                StatisticsCard(
                    icon: {
                        Image("static.weight-used")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    },
                    title: String(localized: "statistics.total.weight.used", bundle: .main),
                    value: formatWeight(totalWeightUsed),
                    backgroundColor: Color(hex: "#B88A5A")
                )
            }
            
            HStack(spacing: 12) {
                // Total Cost Card
                StatisticsCard(
                    icon: {
                        Image("static.total.cost")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    },
                    title: String(localized: "statistics.total.cost", bundle: .main),
                    value: formatCost(totalCost),
                    backgroundColor: Color(hex: "#8BC5D9")
                )
                
                // Total Printing Days Card
                StatisticsCard(
                    icon: {
                        Image("static.calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    },
                    title: String(localized: "statistics.total.printing.days", bundle: .main),
                    value: formatDays(totalPrintingDays),
                    backgroundColor: Color(hex: "#8A7BC4")
                )
            }
        }
    }
    
    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(spacing: 20) {
            // Material Usage Breakdown (Pie Chart)
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "statistics.material.usage.breakdown", bundle: .main))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top)
                
                MaterialUsageBreakdownChart(filaments: allFilaments, logs: filteredLogs)
                    .frame(height: 250)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            
            // Usage Trend Over Time (Line Chart)
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "statistics.usage.trend.over.time", bundle: .main))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top)
                
                StatisticsUsageTrendChart(
                    logs: filteredLogs,
                    timeFilter: selectedTimeFilter,
                    selectedMonths: selectedMonths,
                    selectedYear: selectedYear
                )
                    .frame(height: 200)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .onTapGesture {
                showChartFullscreen(.usageTrend)
            }
            
            // Cost Analysis (Bar Chart)
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "statistics.cost.analysis", bundle: .main))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top)
                
                CostAnalysisChart(filaments: allFilaments, logs: filteredLogs)
                    .frame(height: 200)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .onTapGesture {
                showChartFullscreen(.costAnalysis)
            }
            
            // Usage by Material Type (Horizontal Bar Chart)
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "statistics.usage.by.material", bundle: .main))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top)
                
                UsageByMaterialChart(filaments: allFilaments, logs: filteredLogs)
                    .frame(minHeight: 200)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .onTapGesture {
                showChartFullscreen(.usageByMaterial)
            }
        }
    }
    
    // MARK: - Time Filter Display Text
    private var timeFilterDisplayText: String {
        switch selectedTimeFilter {
        case .month:
            return "最近\(selectedMonths)个月"
        case .year:
            return "\(selectedYear)年"
        case .all:
            return String(localized: "statistics.filter.date.range", bundle: .main)
        }
    }
    
    // MARK: - Statistics Calculations (using filtered logs)
    private var totalSpoolsUsed: Int {
        // Count spools that have usage in the filtered period
        let usedSpoolIds = Set(filteredLogs.compactMap { $0.filament?.id })
        return usedSpoolIds.count
    }
    
    private var totalWeightUsed: Double {
        filteredLogs.reduce(0.0) { $0 + $1.amount }
    }
    
    private var totalCost: Decimal {
        var total: Decimal = 0
        // Calculate cost based on filtered logs
        for log in filteredLogs {
            guard let filament = log.filament,
                  let price = filament.price, price > 0 else { continue }
            // Calculate usage ratio for this log
            let usageRatio = Decimal(log.amount) / Decimal(filament.initialWeight)
            total += price * usageRatio
        }
        return total
    }
    
    private var totalPrintingDays: Int {
        // Count unique days that have printing records
        let calendar = Calendar.current
        let uniqueDays = Set(filteredLogs.map { log in
            calendar.startOfDay(for: log.date)
        })
        return uniqueDays.count
    }
    
    // MARK: - Formatting Helpers
    private func formatWeight(_ grams: Double) -> String {
        if grams >= 1000 {
            return String(format: "%.1fkg", grams / 1000.0)
        } else {
            return String(format: "%.0fg", grams)
        }
    }
    
    private func formatCost(_ cost: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        return formatter.string(from: cost as NSDecimalNumber) ?? "¥0"
    }
    
    private func formatDays(_ days: Int) -> String {
        return "\(days)\(String(localized: "statistics.days.unit", bundle: .main))"
    }
}

// MARK: - Statistics Card
struct StatisticsCard<Icon: View>: View {
    let icon: () -> Icon
    let title: String
    let value: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            icon()
                .frame(width: 36, height: 36)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 70)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor.opacity(0.85))
        .cornerRadius(16)
    }
}

// MARK: - Material Usage Breakdown Chart (Pie Chart)
struct MaterialUsageBreakdownChart: View {
    let filaments: [Filament]
    let logs: [UsageLog]
    
    @Query private var materialColorConfigs: [MaterialColorConfig]
    
    var body: some View {
        if materialUsageData.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(String(localized: "statistics.no.data", bundle: .main))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
        } else {
            Chart {
                ForEach(materialUsageData, id: \.material) { data in
                    SectorMark(
                        angle: .value("Usage", data.percentage),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(colorForMaterial(data.material))
                    .annotation(position: .overlay) {
                        Text("\(data.material) (\(Int(data.percentage))%)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                }
            }
            .frame(height: 250)
        }
    }
    
    private var materialUsageData: [(material: String, percentage: Double)] {
        // Calculate total usage in grams
        let totalUsage = logs.reduce(0.0) { $0 + $1.amount }
        guard totalUsage > 0 else { return [] }
        
        let grouped = Dictionary(grouping: logs) { log in
            log.filament?.material ?? "Unknown"
        }
        
        return grouped.map { (material, logs) in
            let usage = logs.reduce(0.0) { $0 + $1.amount }
            let percentage = (usage / totalUsage) * 100
            return (material: material, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }
    }
    
    private func colorForMaterial(_ material: String) -> Color {
        if let config = materialColorConfigs.first(where: { $0.material.caseInsensitiveCompare(material) == .orderedSame }) {
            return Color(hex: config.colorHex)
        }
        
        // Fallback to a deterministic color based on material name
        let palette = MaterialColorConfig.defaultPalette
        if let index = palette.indices.first {
            let hashValue = abs(material.lowercased().hashValue)
            let color = palette[palette.index(index, offsetBy: hashValue % palette.count)]
            return Color(hex: color)
        }
        
        return Color.gray
    }
}

// MARK: - Usage Trend Chart (Line Chart)
struct StatisticsUsageTrendChart: View {
    let logs: [UsageLog]
    let timeFilter: TimeFilterType
    let selectedMonths: Int
    let selectedYear: Int
    
    @Query private var materialColorConfigs: [MaterialColorConfig]
    
    var body: some View {
        if usageData.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(String(localized: "statistics.no.data", bundle: .main))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        } else {
            Chart {
                ForEach(materialTypes, id: \.self) { material in
                    let data = usageData.filter { $0.material == material }
                    ForEach(data, id: \.period) { item in
                        if timeFilter == .month && selectedMonths == 1 {
                            // For 1 month view, use Date to ensure correct chronological order
                            LineMark(
                                x: .value("Period", item.period),
                                y: .value("Usage", item.usage)
                            )
                            .foregroundStyle(colorForMaterial(material))
                            .interpolationMethod(.catmullRom)
                            .symbol {
                                Circle()
                                    .fill(colorForMaterial(material))
                                    .frame(width: 6, height: 6)
                            }
                        } else {
                            // For other views, use label string
                            LineMark(
                                x: .value("Period", item.periodLabel),
                                y: .value("Usage", item.usage)
                            )
                            .foregroundStyle(colorForMaterial(material))
                            .interpolationMethod(.catmullRom)
                            .symbol {
                                Circle()
                                    .fill(colorForMaterial(material))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .foregroundStyle(by: .value("Material", material))
                }
            }
            .chartXAxis {
                if timeFilter == .month && selectedMonths == 1 {
                    // For 1 month view, show labels every 5 days to avoid overcrowding
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                let calendar = Calendar.current
                                let month = calendar.component(.month, from: date)
                                let day = calendar.component(.day, from: date)
                                Text("\(month).\(day)")
                            }
                        }
                    }
                } else {
                    // For other views, show all labels
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let usage = value.as(Double.self) {
                            if usage >= 1000 {
                                Text(String(format: "%.1fkg", usage / 1000.0))
                            } else {
                                Text("\(Int(usage))g")
                            }
                        }
                    }
                }
            }
            .chartLegend {
                HStack(spacing: 12) {
                    ForEach(materialTypes, id: \.self) { material in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForMaterial(material))
                                .frame(width: 8, height: 8)
                            Text(material)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    private var usageData: [(period: Date, periodLabel: String, material: String, usage: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var periods: [(Date, String)] = []
        
        // Determine grouping based on time filter
        switch timeFilter {
        case .month:
            if selectedMonths == 1 {
                // 1 month: group by day, show last 30 days including today
                for i in 0..<30 {
                    if let dayDate = calendar.date(byAdding: .day, value: -(29 - i), to: now) {
                        let month = calendar.component(.month, from: dayDate)
                        let day = calendar.component(.day, from: dayDate)
                        var components = calendar.dateComponents([.year, .month, .day], from: dayDate)
                        components.hour = 0
                        components.minute = 0
                        components.second = 0
                        if let dayStart = calendar.date(from: components) {
                            periods.append((dayStart, "\(month).\(day)"))
                        }
                    }
                }
            } else {
                // 3, 6, 12 months: group by month (including current month)
                for i in 0..<selectedMonths {
                    if let monthDate = calendar.date(byAdding: .month, value: -(selectedMonths - 1 - i), to: now) {
                        var components = calendar.dateComponents([.year, .month], from: monthDate)
                        components.day = 1
                        if let monthStart = calendar.date(from: components) {
                            let month = calendar.component(.month, from: monthStart)
                            periods.append((monthStart, "\(month)月"))
                        }
                    }
                }
            }
        case .year:
            // Group by month for selected year
            for month in 1...12 {
                var components = DateComponents()
                components.year = selectedYear
                components.month = month
                components.day = 1
                if let monthStart = calendar.date(from: components) {
                    periods.append((monthStart, "\(month)月"))
                }
            }
        case .all:
            // Group by year - get all years from logs
            if !logs.isEmpty {
                let sortedLogs = logs.sorted { $0.date < $1.date }
                let startYear = calendar.component(.year, from: sortedLogs.first!.date)
                let endYear = calendar.component(.year, from: sortedLogs.last!.date)
                
                for year in startYear...endYear {
                    var components = DateComponents()
                    components.year = year
                    components.month = 1
                    components.day = 1
                    if let yearStart = calendar.date(from: components) {
                        periods.append((yearStart, "\(year)年"))
                    }
                }
            }
        }
        
        var result: [(Date, String, String, Double)] = []
        for (periodStart, periodLabel) in periods {
            let periodEnd: Date
            switch timeFilter {
            case .month:
                if selectedMonths == 1 {
                    periodEnd = calendar.date(byAdding: .day, value: 1, to: periodStart) ?? periodStart
                } else {
                    periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart) ?? periodStart
                }
            case .year:
                periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart) ?? periodStart
            case .all:
                periodEnd = calendar.date(byAdding: .year, value: 1, to: periodStart) ?? periodStart
            }
            
            let periodLogs = logs.filter { log in
                log.date >= periodStart && log.date < periodEnd
            }
            
            let grouped = Dictionary(grouping: periodLogs) { log in
                log.filament?.material ?? "Unknown"
            }
            
            for (material, materialLogs) in grouped {
                let usage = materialLogs.reduce(0.0) { total, log in
                    return total + log.amount
                }
                result.append((periodStart, periodLabel, material, usage))
            }
        }
        
        return result
    }
    
    private var materialTypes: [String] {
        Array(Set(usageData.map { $0.material })).sorted()
    }
    
    private func colorForMaterial(_ material: String) -> Color {
        if let config = materialColorConfigs.first(where: { $0.material.caseInsensitiveCompare(material) == .orderedSame }) {
            return Color(hex: config.colorHex)
        }
        
        let palette = MaterialColorConfig.defaultPalette
        if let index = palette.indices.first {
            let hashValue = abs(material.lowercased().hashValue)
            let color = palette[palette.index(index, offsetBy: hashValue % palette.count)]
            return Color(hex: color)
        }
        
        return Color.gray
    }
}

// MARK: - Cost Analysis Chart (Bar Chart)
struct CostAnalysisChart: View {
    let filaments: [Filament]
    let logs: [UsageLog]
    
    @Query private var materialColorConfigs: [MaterialColorConfig]
    
    var body: some View {
        if costData.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(String(localized: "statistics.no.data", bundle: .main))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        } else {
            Chart {
                ForEach(costData, id: \.material) { data in
                    BarMark(
                        x: .value("Material", data.material),
                        y: .value("Cost", data.cost)
                    )
                    .foregroundStyle(colorForMaterial(data.material))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        Text(formatCost(data.cost))
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let cost = value.as(Decimal.self) {
                            Text(formatCost(cost))
                        }
                    }
                }
            }
        }
    }
    
    private var costData: [(material: String, cost: Decimal)] {
        var materialCosts: [String: Decimal] = [:]
        
        // Calculate cost based on filtered logs
        for log in logs {
            guard let filament = log.filament,
                  let price = filament.price, price > 0 else { continue }
            
            // Calculate usage ratio for this log entry
            let usageRatio = Decimal(log.amount) / Decimal(filament.initialWeight)
            let cost = price * usageRatio
            let material = filament.material
            materialCosts[material, default: 0] += cost
        }
        
        return materialCosts.map { (material: $0.key, cost: $0.value) }
            .sorted { $0.cost > $1.cost }
    }
    
    private func colorForMaterial(_ material: String) -> Color {
        if let config = materialColorConfigs.first(where: { $0.material.caseInsensitiveCompare(material) == .orderedSame }) {
            return Color(hex: config.colorHex)
        }
        
        let palette = MaterialColorConfig.defaultPalette
        if let index = palette.indices.first {
            let hashValue = abs(material.lowercased().hashValue)
            let color = palette[palette.index(index, offsetBy: hashValue % palette.count)]
            return Color(hex: color)
        }
        
        return Color.gray
    }
    
    private func formatCost(_ cost: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        return formatter.string(from: cost as NSDecimalNumber) ?? "¥0"
    }
}

// MARK: - Usage by Material Chart (Horizontal Bar Chart)
struct UsageByMaterialChart: View {
    let filaments: [Filament]
    let logs: [UsageLog]
    
    @Query private var materialColorConfigs: [MaterialColorConfig]
    
    var body: some View {
        if usageData.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.horizontal")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(String(localized: "statistics.no.data", bundle: .main))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        } else {
            HStack(spacing: 0) {
                // Material labels on the left
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(usageData, id: \.material) { data in
                        Text(data.material)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(height: 24, alignment: .center)
                    }
                }
                .frame(width: 60)
                .padding(.trailing, 8)
                
                // Chart on the right
                Chart(usageData, id: \.material) { data in
                    BarMark(
                        x: .value("Usage", data.usage),
                        y: .value("Material", data.material)
                    )
                    .foregroundStyle(colorForMaterial(data.material))
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(formatWeight(data.usage))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.leading, 4)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let usage = value.as(Double.self) {
                                if usage >= 1000 {
                                    Text(String(format: "%.1fkg", usage / 1000.0))
                                } else {
                                    Text("\(Int(usage))g")
                                }
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartPlotStyle { plotArea in
                    // 保证每个柱状条的高度和左侧文字一致（24）
                    plotArea.frame(height: CGFloat(usageData.count) * 24)
                }
                .padding(.top, 16)
            }
        }
    }
    
    private var usageData: [(material: String, usage: Double)] {
        var materialUsage: [String: Double] = [:]
        
        for log in logs {
            guard let filament = log.filament else { continue }
            let material = filament.material
            materialUsage[material, default: 0] += log.amount
        }
        
        return materialUsage.map { (material: $0.key, usage: $0.value) }
            .sorted { $0.usage > $1.usage }
    }
    
    private func colorForMaterial(_ material: String) -> Color {
        if let config = materialColorConfigs.first(where: { $0.material.caseInsensitiveCompare(material) == .orderedSame }) {
            return Color(hex: config.colorHex)
        }
        
        let palette = MaterialColorConfig.defaultPalette
        if let index = palette.indices.first {
            let hashValue = abs(material.lowercased().hashValue)
            let color = palette[palette.index(index, offsetBy: hashValue % palette.count)]
            return Color(hex: color)
        }
        
        return Color.gray
    }
    
    private func formatWeight(_ grams: Double) -> String {
        if grams >= 1000 {
            return String(format: "%.1fkg", grams / 1000.0)
        } else {
            return String(format: "%.0fg", grams)
        }
    }
}

// MARK: - Chart Detail View (Fullscreen Landscape)
struct ChartDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let chartType: ChartType
    let filaments: [Filament]
    let logs: [UsageLog]
    let timeFilter: TimeFilterType
    let selectedMonths: Int
    let selectedYear: Int
    
    var body: some View {
        ZStack {
            // Background - follow system
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header with title and close button
                HStack {
                    Text(chartTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        // Restore orientation and dismiss immediately
                        restoreOrientationAndDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                // Chart content
                chartContent
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBar(hidden: true)
        .onDisappear {
            // Restore all orientations when view disappears
            AppDelegate.orientationLock = .all
            // Request rotation back to portrait
            if #available(iOS 16.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
            }
            // Trigger orientation update
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    private func restoreOrientationAndDismiss() {
        // Restore all orientations
        AppDelegate.orientationLock = .all
        // Request rotation back to portrait
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
        // Trigger orientation update
        UIViewController.attemptRotationToDeviceOrientation()
        
        // Dismiss immediately so rotation happens while dismissing
        dismiss()
    }
    
    private var chartTitle: String {
        switch chartType {
        case .usageTrend:
            return String(localized: "statistics.usage.trend.over.time", bundle: .main)
        case .costAnalysis:
            return String(localized: "statistics.cost.analysis", bundle: .main)
        case .usageByMaterial:
            return String(localized: "statistics.usage.by.material", bundle: .main)
        }
    }
    
    @ViewBuilder
    private var chartContent: some View {
        switch chartType {
        case .usageTrend:
            StatisticsUsageTrendChart(
                logs: logs,
                timeFilter: timeFilter,
                selectedMonths: selectedMonths,
                selectedYear: selectedYear
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .costAnalysis:
            CostAnalysisChart(filaments: filaments, logs: logs)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .usageByMaterial:
            UsageByMaterialChart(filaments: filaments, logs: logs)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
