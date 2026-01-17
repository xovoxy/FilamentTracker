//
//  LanguagePickerView.swift
//  FilamentTracker
//
//  Language selection view
//

import SwiftUI
import SwiftData

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    
    @ObservedObject var languageManager: LanguageManager
    @State private var showRestartAlert = false
    @State private var selectedLanguage: Language?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Language.allCases, id: \.self) { language in
                    Button {
                        if languageManager.currentLanguage != language {
                            selectedLanguage = language
                            showRestartAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Text(languageDisplayName(language))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "home.language", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "cancel", bundle: .main)) {
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "home.language.restart.title", bundle: .main), isPresented: $showRestartAlert) {
                Button(String(localized: "cancel", bundle: .main), role: .cancel) {
                    selectedLanguage = nil
                }
                Button(String(localized: "home.language.restart.confirm", bundle: .main)) {
                    if let language = selectedLanguage {
                        applyLanguageChange(language)
                    }
                }
            } message: {
                Text(String(localized: "home.language.restart.message", bundle: .main))
            }
        }
    }
    
    private func languageDisplayName(_ language: Language) -> String {
        switch language {
        case .system:
            return String(localized: "home.language.system", bundle: .main)
        case .english:
            return String(localized: "home.language.english", bundle: .main)
        case .chinese:
            return String(localized: "home.language.chinese", bundle: .main)
        }
    }
    
    private func applyLanguageChange(_ language: Language) {
        languageManager.setLanguage(language)
        
        // Also update AppSettings if it exists
        let settings = appSettings.first ?? AppSettings()
        if appSettings.isEmpty {
            modelContext.insert(settings)
        }
        settings.languageSetting = language
        try? modelContext.save()
        
        dismiss()
        
        // Restart app to apply language change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            exit(0)
        }
    }
}

#Preview {
    LanguagePickerView(languageManager: LanguageManager.shared)
        .modelContainer(for: [Filament.self, UsageLog.self, AppSettings.self], inMemory: true)
}
