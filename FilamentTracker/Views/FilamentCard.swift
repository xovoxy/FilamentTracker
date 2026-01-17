//
//  FilamentCard.swift
//  FilamentTracker
//
//  Card view for displaying a filament spool
//

import SwiftUI

struct FilamentCard: View {
    let filament: Filament
    var onLogUsage: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            // Color representation
            Circle()
                .fill(Color(hex: filament.colorHex))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Brand and material
            VStack(spacing: 4) {
                Text(filament.brand.isEmpty ? String(localized: "card.unknown", bundle: .main) : filament.brand)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(filament.material)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(filament.colorName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .lineLimit(1)
            }
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: filament.remainingPercentage / 100)
                    .stroke(
                        filament.isLowStock ? Color.orange : Color.teal,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(filament.remainingPercentage))%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            // Quick action button
            Button {
                onLogUsage?()
            } label: {
                Text(String(localized: "detail.log.usage", bundle: .main))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.teal)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    FilamentCard(filament: Filament(
        brand: "Bambu Lab",
        material: "PLA",
        colorName: "Black",
        colorHex: "#000000",
        initialWeight: 1000,
        remainingWeight: 750
    )) {
        print("Log usage")
    }
    .padding()
}
