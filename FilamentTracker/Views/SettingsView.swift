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
                            Label("Archive Management", systemImage: "archivebox")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Manage archived filaments and restore or delete them")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
