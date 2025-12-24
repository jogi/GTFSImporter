# Small GTFS Test Dataset

This is a **small subset of real VTA GTFS data** extracted from the parent `testData/` directory.

## Contents

- **5 trips** (Blue Line)
- **130 stop_times** (real timepoint data with interpolation)
- **26 stops** (actual VTA station locations)
- **1 route** (Blue Line: Baypointe - Santa Teresa)
- **3 calendar entries** (real service patterns)
- **30 calendar_dates** (service exceptions)
- **958 shape points** (actual geographic path)
- **1 agency** (VTA)

## Purpose

This dataset is for **fast integration tests** that need real GTFS data but don't want to import the full ~428K stop_times dataset.

**Benefits:**
- ✅ Real production data structure and values
- ✅ Maintains full referential integrity
- ✅ Fast imports (~0.1 seconds vs ~60 seconds for full dataset)
- ✅ Tests actual CSV parsing and data relationships
- ✅ Includes edge cases from real data (overnight times, timepoint=0, etc.)

## Regenerating

To regenerate this subset from the parent testData directory:

```swift
// See git history for the create_test_subset.swift script
// It extracts the first N trips and follows all foreign key relationships
```

## Usage in Tests

```swift
// Use this for fast integration tests with real data
let gtfsPath = TestDataHelper.smallRealTestDataPath()
let importer = Importer(path: gtfsPath)
try importer.importAllFiles()
```

For tests needing the full dataset, use:
```swift
let gtfsPath = TestDataHelper.fullTestDataPath()
```
