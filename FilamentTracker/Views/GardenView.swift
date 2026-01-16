//
//  GardenView.swift
//  FilamentTracker
//
//  Main garden view showing all filament spools
//

import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Filament> { !$0.isArchived }) private var filaments: [Filament]
    @State private var searchText = ""
    @State private var selectedMaterial: String? = nil
    @State private var showAddMaterial = false
    @State private var selectedFilamentForUsage: Filament? = nil
    
    private let materials = ["PLA", "PETG", "ABS", "TPU", "Other"]
    
    var filteredFilaments: [Filament] {
        var result = filaments
        
        if !searchText.isEmpty {
            result = result.filter { filament in
                filament.brand.localizedCaseInsensitiveContains(searchText) ||
                filament.colorName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let material = selectedMaterial {
            result = result.filter { $0.material == material }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filter bar
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedMaterial == nil
                            ) {
                                selectedMaterial = nil
                            }
                            
                            ForEach(materials, id: \.self) { material in
                                FilterChip(
                                    title: material,
                                    isSelected: selectedMaterial == material
                                ) {
                                    selectedMaterial = selectedMaterial == material ? nil : material
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                // Filament grid
                if filteredFilaments.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredFilaments) { filament in
                                NavigationLink(destination: DetailView(filament: filament)) {
                                    FilamentCard(filament: filament, onLogUsage: {
                                        selectedFilamentForUsage = filament
                                    })
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Organize Your Print Materials")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddMaterial = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddMaterial) {
                AddMaterialView()
            }
            .sheet(item: $selectedFilamentForUsage) { filament in
                TrackUsageView(filament: filament)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search by brand or color", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "#8B9A7D") : Color(.systemBackground))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "spool")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Filaments Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first filament spool to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    GardenView()
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
