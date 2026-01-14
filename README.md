# Filament Tracker (Filament Garden)

A native iOS application for managing 3D printer filament spools, tracking usage, and monitoring inventory.

## Features

- **Garden View**: Visual grid of all filament spools with progress indicators
- **Material Management**: Add and edit filament spools with detailed information
- **Usage Tracking**: Log usage by weight, length, or gross weight measurement
- **Analytics**: View usage trends and material distribution charts
- **Reminders**: Get alerts for low stock, drying needs, and maintenance
- **Smart Calculations**: Automatic conversion between weight and length using material density

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Localization**: English & Chinese (Simplified)

## Project Structure

```
FilamentTracker/
├── FilamentTrackerApp.swift      # App entry point
├── Models/
│   ├── Filament.swift            # Filament spool model
│   ├── UsageLog.swift            # Usage tracking model
│   └── AppSettings.swift         # User settings model
├── Views/
│   ├── ContentView.swift         # Main tab view
│   ├── GardenView.swift          # Home/inventory view
│   ├── FilamentCard.swift        # Spool card component
│   ├── AddMaterialView.swift     # Add/edit material form
│   ├── DetailView.swift          # Filament detail view
│   ├── TrackUsageView.swift      # Usage logging view
│   ├── AnalyticsView.swift       # Statistics and charts
│   └── RemindersView.swift       # Reminders and alerts
├── Utilities/
│   └── FilamentCalculator.swift  # Weight/length conversion utilities
└── Resources/
    ├── Info.plist
    └── Localization files
```

## Data Models

### Filament
Represents a physical spool of filament with properties like brand, material type, color, weight, temperature settings, etc.

### UsageLog
Tracks individual usage events with amount, date, note, and type (print, failed print, calibration, manual adjustment).

### AppSettings
User preferences including default diameter, low stock threshold, currency, and language.

## Key Features

### Weight Calculations
- Supports gross weight (entire spool) to net weight (filament only) conversion
- Requires empty spool weight for accurate tracking

### Unit Conversions
- Converts between meters and grams using material density
- Supports common materials: PLA, PETG, ABS, TPU

### Usage Tracking Methods
1. **By Amount**: Direct input of grams used
2. **By Length**: Input meters, automatically converts to grams
3. **By Weight**: Input current gross weight, calculates used amount

## Setup Instructions

1. Open the project in Xcode
2. Select your development team in project settings
3. Build and run on iOS 17+ simulator or device

## Localization

The app supports English and Simplified Chinese. Localization strings are located in:
- `en.lproj/Localizable.strings`
- `zh-Hans.lproj/Localizable.strings`

## Future Enhancements

- CloudKit sync for multi-device support
- Barcode scanning for automatic material identification
- Photo storage for spool labels
- Advanced analytics and reporting
- Export data functionality

## License

Copyright © 2024
