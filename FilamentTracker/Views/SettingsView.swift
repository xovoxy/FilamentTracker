//
//  SettingsView.swift
//  FilamentTracker
//
//  Settings and preferences view
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showArchiveManagement = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showArchiveManagement = true
                    } label: {
                        HStack {
                            Label(String(localized: "archive.title", bundle: .main), systemImage: "archivebox")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(String(localized: "settings.data.management", bundle: .main))
                } footer: {
                    Text(String(localized: "settings.data.management.description", bundle: .main))
                }
            }
            .navigationTitle(String(localized: "settings.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "archive.done", bundle: .main)) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showArchiveManagement) {
                ArchiveManagementView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
