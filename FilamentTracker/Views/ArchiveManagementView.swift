//
//  ArchiveManagementView.swift
//  FilamentTracker
//
//  View for managing archived filaments
//

import SwiftUI
import SwiftData

struct ArchiveManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Filament> { $0.isArchived }) private var archivedFilaments: [Filament]
    
    @State private var filamentToRestore: Filament?
    @State private var filamentToDelete: Filament?
    @State private var showRestoreAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedMaterialFilter: String? = nil
    
    // Get filtered archived filaments
    var filteredFilaments: [Filament] {
        if let selectedMaterial = selectedMaterialFilter {
            return archivedFilaments.filter { $0.material == selectedMaterial }
        } else {
            return archivedFilaments
        }
    }
    
    // Get all available material types from archived filaments
    var availableMaterials: [String] {
        let materials = Set(archivedFilaments.map { $0.material })
        return Array(materials).sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching home page
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#EBEBE0"),
                        Color(hex: "#E0EBF0")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Summary Section
                    summarySection
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    
                    // Material Filter
                    if !availableMaterials.isEmpty {
                        materialFilterSection
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                    }
                    
                    // Archived Filaments List
                    if filteredFilaments.isEmpty {
                        emptyStateView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredFilaments) { filament in
                                ArchivedFilamentRow(
                                    filament: filament,
                                    onRestore: {
                                        filamentToRestore = filament
                                        showRestoreAlert = true
                                    },
                                    onDelete: {
                                        filamentToDelete = filament
                                        showDeleteAlert = true
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Archive Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Restore Filament", isPresented: $showRestoreAlert) {
                Button("Cancel", role: .cancel) {
                    filamentToRestore = nil
                }
                Button("Restore") {
                    if let filament = filamentToRestore {
                        restoreFilament(filament)
                        filamentToRestore = nil
                    }
                }
            } message: {
                if let filament = filamentToRestore {
                    Text("Restore \(filament.brand.isEmpty ? "" : filament.brand + " ")\(filament.colorName) \(filament.material) spool?")
                }
            }
            .alert("Delete Filament", isPresented: $showDeleteAlert) {
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
                    Text("Are you sure you want to permanently delete this \(filament.brand.isEmpty ? "" : filament.brand + " ")\(filament.colorName) \(filament.material) spool? This action cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(archivedFilaments.count)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Archived Spools")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !archivedFilaments.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(availableMaterials.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Material Types")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(12)
    }
    
    // MARK: - Material Filter Section
    private var materialFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedMaterialFilter == nil
                ) {
                    selectedMaterialFilter = nil
                }
                
                ForEach(availableMaterials, id: \.self) { material in
                    FilterChip(
                        title: material,
                        isSelected: selectedMaterialFilter == material
                    ) {
                        selectedMaterialFilter = material
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Archived Filaments")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Archived filaments will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Actions
    private func restoreFilament(_ filament: Filament) {
        filament.isArchived = false
        try? modelContext.save()
    }
    
    private func deleteFilament(_ filament: Filament) {
        modelContext.delete(filament)
        try? modelContext.save()
    }
}

// MARK: - Archived Filament Row
struct ArchivedFilamentRow: View {
    let filament: Filament
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    @State private var showSwipeHint = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Action buttons background (shown when swiped)
            HStack(spacing: 8) {
                Spacer()
                
                // Restore button
                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            showSwipeHint = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onRestore()
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color(hex: "#7FD4B0"))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    
                    Text("Restore")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Delete button
                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            showSwipeHint = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.red)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    
                    Text("Delete")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(.trailing, 5)
            .opacity(showSwipeHint ? 1 : 0)
            
            // Main content
            HStack(spacing: 12) {
                // Color Indicator
                Circle()
                    .fill(Color(hex: filament.colorHex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                
                // Filament Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(filament.colorName) \(filament.material)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        if !filament.brand.isEmpty {
                            Text(filament.brand)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(Int(filament.remainingWeight))g remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(12)
            .offset(x: showSwipeHint ? -60 : 0)
            .animation(.easeInOut(duration: 0.3), value: showSwipeHint)
            .onTapGesture {
                // Trigger swipe hint animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSwipeHint = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSwipeHint = false
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Delete button (rightmost)
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            // Restore button (left of delete)
            Button(action: onRestore) {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(Color(hex: "#7FD4B0"))
        }
    }
}


#Preview {
    ArchiveManagementView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
