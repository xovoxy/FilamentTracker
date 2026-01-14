# Filament Tracker - iOS App Design Document

## 1. Overview
The **Filament Tracker** (Filament Garden) is a native iOS application designed to help 3D printing enthusiasts manage their collection of filament spools. It allows users to track inventory, log usage, monitor remaining amounts, and view usage statistics.

The app focuses on a visual and intuitive "Garden" interface where each spool is treated as an asset to be nurtured (tracked).

## 2. Architecture
*   **Platform**: iOS 17+ (Native)
*   **UI Framework**: SwiftUI
*   **Data Persistence**: SwiftData (Local-first)
*   **Localization**: English & Chinese (Simplified) support
*   **Sync (Optional Future)**: CloudKit (via SwiftData automatic sync)

## 3. Data Model

### 3.1. Filament (Spool)
Represents a physical spool of filament.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `UUID` | Unique identifier |
| `brand` | `String` | e.g., Bambu Lab, Polymaker, eSun |
| `material` | `String` | e.g., PLA, PETG, ABS, TPU |
| `colorName` | `String` | User-defined color name |
| `colorHex` | `String` | Visual representation of color |
| `diameter` | `Double` | 1.75mm or 2.85mm (Default: 1.75) |
| `initialWeight` | `Double` | Net weight in grams (e.g., 1000g) |
| `remainingWeight` | `Double` | Current net weight in grams |
| `emptySpoolWeight` | `Double?` | Weight of the spool itself (for weighing logic) |
| `density` | `Double?` | g/cm³ (for length <-> weight conversion) |
| `minTemp` | `Int?` | Min nozzle temp (°C) |
| `maxTemp` | `Int?` | Max nozzle temp (°C) |
| `bedTemp` | `Int?` | Recommended bed temp (°C) |
| `price` | `Decimal?` | Cost of the spool |
| `purchaseDate` | `Date` | Date acquired |
| `isArchived` | `Boolean` | True if spool is finished/gone |
| `logs` | `[UsageLog]` | Relationship to usage history |

### 3.2. UsageLog
Tracks specific print jobs or manual adjustments.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `UUID` | Unique identifier |
| `filament` | `Filament` | Relationship to parent spool |
| `amount` | `Double` | Amount used (grams) |
| `date` | `Date` | When the usage occurred |
| `note` | `String?` | Project name or reason (e.g., "Benchy", "Calibration") |
| `type` | `Enum` | `print`, `failed_print`, `calibration`, `manual_adjustment` |

### 3.3. Settings
User preferences.

| Field | Type | Description |
| :--- | :--- | :--- |
| `defaultDiameter` | `Double` | 1.75 or 2.85 |
| `lowStockThreshold` | `Double` | Percentage (e.g., 20%) to trigger warning |
| `currency` | `String` | Symbol for price display |
| `language` | `Enum` | `system` (default), `en`, `zh_Hans` |

## 4. UI/UX Flow & Screen Design

### 4.1. The Garden (Home/Inventory)
*   **Visual**: A grid or list view showing available spools.
*   **Cards**: Each card displays:
    *   Brand/Type/Color pill.
    *   Visual progress bar (circle or bar) showing `remainingWeight / initialWeight`.
    *   Quick Action: "Log Usage".
*   **Filtering**: By Material (PLA/PETG), Color, or Low Stock.
*   **Search**: By Brand or Color name.

### 4.2. Add/Edit Material (Form)
*   **Photo**: "Take Photo" or "Choose from Library" to save a visual reference of the spool label.
*   **Scanning (Future)**: Placeholder for barcode scanning to auto-fill common brands.
*   **Fields**:
    *   **Essential**: Brand, Material, Color, Initial Weight.
    *   **Advanced**: Empty Spool Weight (Critical for logic), Diameter, Temp Range, Price.
    *   **Presets**: Quick selection buttons for common settings (e.g., "Generic PLA", "Bambu Basic").

### 4.3. Track Usage (Action Sheet / Modal)
*   **Entry**:
    *   **By Weight**: Input *current measured gross weight*. System calculates used amount:
        `Used = Previous_Remaining - (Current_Gross - Empty_Spool_Weight)`
    *   **By Amount**: "Used 50g".
    *   **By Length**: "Used 10m" (Requires density conversion).
*   **Context**: Optional "Project Name" field.

### 4.4. Detail View
*   **Header**: Large color representation, Brand, Type.
*   **Stats**: Remaining %, Days since open, Total prints.
*   **Chart**: Mini line chart of remaining weight over time.
*   **History**: List of `UsageLog` entries.
*   **Actions**: Edit, Archive, Log Usage.

### 4.5. Stats & Analytics (Dashboard)
*   **Charts**:
    *   Material Distribution (Pie Chart: PLA vs PETG).
    *   Usage Trends (Bar Chart: Grams used per month).
    *   Cost Analysis (Total value of inventory, Cost of used filament).

## 5. Logic Enhancements & Gaps Analysis

The following logic covers gaps identified in the initial flow diagram:

### 5.1. Gross vs. Net Weight (The "Empty Spool" Problem)
*   **Problem**: Users typically weigh the *entire* spool (Gross Weight) to check stock, but the app tracks *filament* (Net Weight).
*   **Solution**:
    1.  Allow user to input `Empty Spool Weight` in settings or per spool (default to generic ~200g if unknown).
    2.  **Calculator Tool**: When logging usage, offer a "Weigh-in" mode:
        *   Input: `Current Gross Weight`
        *   Formula: `New Net Weight = Current Gross Weight - Empty Spool Weight`
        *   Action: Update `remainingWeight` automatically.

### 5.2. Unit Conversions (Slicer Integration)
*   **Problem**: Slicers (Cura, Bambu Studio) often estimate usage in **Meters**, but spools are sold by **Grams**.
*   **Solution**:
    *   Implement density constants for common materials:
        *   PLA: ~1.24 g/cm³
        *   PETG: ~1.27 g/cm³
        *   ABS: ~1.04 g/cm³
    *   Allow input in Meters -> Auto-convert to Grams for storage.
    *   Formula: `Weight (g) = Length (cm) * Area (cm²) * Density (g/cm³)`
        *   `Area = π * (diameter/2)²`

### 5.3. Spool Lifecycle States
*   **Active**: Currently in the "Garden".
*   **Archived**: Finished spools (0g remaining) or discarded ones. Kept for historical stats but hidden from main view.
*   **Logic**: Auto-archive when weight hits 0, or manual toggle.

### 5.4. Multiple Spools of Same Type
*   **Scenario**: User buys 3 rolls of "Bambu Black PLA".
*   **Logic**: Treat them as distinct entities (unique IDs) to track individual usage, but allow "Duplicate" action to quickly add new stock.

## 6. Implementation Plan
1.  **Setup**: Initialize iOS Project with SwiftData container and Localization files (en/zh).
2.  **Models**: Define `Filament` and `UsageLog` classes.
3.  **Core UI**: Build the "Garden" grid and "Add Spool" form.
4.  **Logic**: Implement the Gross-to-Net calculator and Unit Converter helper.
5.  **Refinement**: Add Charts and Polish UI.
