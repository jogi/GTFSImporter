# CLAUDE.md - GTFSImporter

## Project Overview

GTFSImporter is a Swift command-line tool that imports GTFS (General Transit Feed Specification) data from CSV files into a SQLite database. It modernizes the legacy Python-based importer while maintaining full compatibility with the legacy database format.

## Architecture

### Core Components

```
GTFSImporter/
├── Sources/gtfs-importer/
│   ├── main.swift                    # Entry point, CLI argument parsing
│   ├── Importing/
│   │   ├── Importer.swift           # Main import orchestrator
│   │   ├── Agency+Importing.swift   # Agency CSV import
│   │   ├── Calendar+Importing.swift # Calendar CSV import
│   │   ├── CalendarDates+Importing.swift # Calendar dates import
│   │   ├── Direction+Importing.swift     # Directions import
│   │   ├── FareAttribute+Importing.swift # Fare attributes import
│   │   ├── FareRule+Importing.swift      # Fare rules import
│   │   ├── Route+Importing.swift         # Routes import
│   │   ├── Shape+Importing.swift         # Shapes import
│   │   ├── Stop+Importing.swift          # Stops import
│   │   ├── StopTime+Importing.swift      # Stop times import
│   │   ├── Trip+Importing.swift          # Trips import
│   │   └── StopRoute.swift               # Stop-route relationships
│   ├── Utilities/
│   │   └── StopTimeInterpolator.swift   # Time interpolation algorithm
│   └── Extensions/
│       ├── Console.swift                 # Terminal output colors
│       ├── Logger.swift                  # OSLog configuration
│       └── String.swift                  # String extensions
└── Package.swift                         # Swift Package Manager config
```

### Import Process Flow

1. **Initialize Database**: Create SQLite database at `./gtfs.db`
2. **Import CSV Files**: Read each GTFS CSV file and insert records
3. **Post-Processing**:
   - Add stop-routes relationships (optional with `--add-stop-routes`)
   - Vacuum database (compact and optimize)
   - Reindex all tables
   - Interpolate missing stop times

### Stop Time Interpolation

The interpolator fills in missing arrival/departure times for stops between timepoints using distance-based interpolation:

**Algorithm** (in `StopTimeInterpolator.swift`):
1. For each trip, identify timepoints (stops with explicit `arrival_time` in CSV)
2. Calculate total distance between consecutive timepoints using Haversine formula
3. For stops without times between timepoints:
   - Calculate cumulative distance from previous timepoint
   - Interpolate time: `time = start_time + (distance_traveled / total_distance) × time_between_timepoints`
   - Set `timepoint=0` to indicate interpolated time
4. Preserve original `timepoint` values for stops with explicit times

**Key Implementation Details**:
- Haversine formula calculates great-circle distance between lat/lon coordinates
- Earth radius: 6,378,135 meters
- Only updates stops that actually needed interpolation
- Respects GTFS spec semantics for timepoint field

## Database Schema

The generated SQLite database includes these tables:
- `agency`: Transit agency information
- `calendar`: Service calendar (which days services run)
- `calendar_dates`: Calendar exceptions (added/removed service days)
- `directions`: Route direction metadata
- `fare_attributes`: Fare pricing information
- `fare_rules`: Rules for applying fares
- `routes`: Transit routes
- `shapes`: Geographic paths for routes
- `stops`: Stop/station locations
- `stop_times`: Arrival/departure times for each stop on each trip
- `trips`: Individual trip instances

### Indexes

Performance indexes created:
- `stops_on_stop_lat`, `stops_on_stop_lon`: Geographic proximity queries
- `shapes_on_shape_id`: Shape lookup
- `trips_on_route_id`, `trips_on_service_id`: Trip filtering
- `stop_times_on_trip_id`, `stop_times_on_stop_id`: Stop time queries
- `calendar_dates_on_service_id`: Calendar exception lookup

## Dependencies

### External Packages
- **GTFSModel**: Data models and database schema (from GitHub)
- **GRDB**: SQLite database toolkit
- **ArgumentParser**: Command-line argument parsing
- **CSV.swift**: CSV file parsing

### Local Development
For testing changes to GTFSModel:
1. Update `Package.swift` to use local path: `.package(path: "../GTFSModel")`
2. Test changes
3. Revert to remote: `.package(url: "https://github.com/jogi/GTFSModel", .branch("main"))`

## Usage

```bash
# Build the project
swift build

# Run the importer
.build/debug/gtfs-importer --path /path/to/gtfs/csv/files

# Add stop-routes relationships (optional)
.build/debug/gtfs-importer --path /path/to/gtfs --add-stop-routes
```

### Expected Input

GTFS feed directory containing CSV files:
- `agency.txt` (required)
- `calendar.txt` (required)
- `calendar_dates.txt` (optional)
- `directions.txt` (optional, extension)
- `fare_attributes.txt` (optional)
- `fare_rules.txt` (optional)
- `routes.txt` (required)
- `shapes.txt` (optional)
- `stops.txt` (required)
- `stop_times.txt` (required)
- `trips.txt` (required)

### Output

Single SQLite database file: `./gtfs.db`

## Testing

### Compatibility Testing

To verify compatibility with legacy database:

```bash
# 1. Backup legacy database
cp gtfs.db gtfs_legacy.db

# 2. Build and run new importer
swift build
rm gtfs.db
.build/debug/gtfs-importer -p ../GTFS/google_transit

# 3. Compare schemas
sqlite3 gtfs_legacy.db ".schema" > legacy_schema.txt
sqlite3 gtfs.db ".schema" > new_schema.txt

# 4. Compare data
sqlite3 gtfs_legacy.db "SELECT * FROM routes ORDER BY route_id LIMIT 5"
sqlite3 gtfs.db "SELECT * FROM routes ORDER BY route_id LIMIT 5"

# 5. Verify indexes
sqlite3 gtfs.db "SELECT name FROM sqlite_master WHERE type='index' ORDER BY name"
```

### Expected Performance

For VTA GTFS feed (~390K stop_times):
- Total import time: ~60 seconds
- Stop times import: ~50 seconds (bulk of time)
- Vacuum: ~1 second
- Reindex: <1 second
- Interpolation: ~1 second (minimal if all times present)

## Code Conventions

### Import Pattern

Each GTFS entity has an `+Importing.swift` extension that implements:

```swift
extension EntityType: ImporterImporting {
    static var fileName: String { "entity_file.txt" }
    // Inherits importFile(from:) from ImporterImporting
}
```

The `ImporterReceiving` protocol handles the actual CSV parsing and database insertion.

### Color Output

Use console color extensions for user-friendly output:
- `.green`: Success messages, counts
- `.magenta`: File names, entity types
- `.yellow`: Paths, warnings

### Logging

Use `OSLog` for structured logging:
```swift
Logger.importer.info("Message")
Logger.importer.error("Error: \(error)")
```

## Common Issues

### Missing Dependencies
If build fails with "no such module 'GTFSModel'":
- Clean build: `swift package clean`
- Resolve dependencies: `swift package resolve`
- Rebuild: `swift build`

### Database Locked
If import fails with "database is locked":
- Ensure no other processes have `gtfs.db` open
- Delete `gtfs.db` and try again

### Memory Issues
For very large GTFS feeds:
- Consider batching inserts in `receiveImport`
- Monitor memory usage during import

## Legacy Compatibility

This Swift implementation maintains 100% data compatibility with the legacy Python importer:
- Column order may differ but data is identical when queried by name
- All legacy indexes are preserved
- New tables (calendar_dates, directions) are additions, not replacements
- Type changes follow GTFS specification exactly

## Future Enhancements

Potential improvements:
- [ ] Parallel CSV parsing for faster imports
- [ ] Progress bar for large imports
- [ ] Validation of GTFS data against spec
- [ ] Export functionality (SQLite → GTFS CSV)
- [ ] Differential updates (update existing database vs. full rebuild)
