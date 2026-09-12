# GTFSImporter

A Swift command-line tool that imports GTFS (General Transit Feed Specification) data from CSV files into a SQLite database.

## Features

- Imports standard GTFS CSV files into a SQLite database
- Interpolates missing stop times using distance-based calculations
- Generates stop-route relationships for efficient queries
- Maintains compatibility with legacy database schema
- Colored console output for better readability

## Requirements

- Swift 5.3+
- macOS 11+ or iOS 12+

## Installation

```bash
swift build
```

## Usage

```bash
# Basic import
.build/debug/gtfs-importer --path /path/to/gtfs/csv/files

# With stop-routes relationships
.build/debug/gtfs-importer --path /path/to/gtfs --add-stop-routes
```

### Input

GTFS feed directory containing standard CSV files:
- `agency.txt`, `calendar.txt`, `routes.txt`, `stops.txt`, `stop_times.txt`, `trips.txt` (required)
- `calendar_dates.txt`, `shapes.txt`, `fare_attributes.txt`, `fare_rules.txt`, `directions.txt` (optional)

### Output

Single SQLite database file: `./gtfs.db`

## Dependencies

- [GTFSModel](https://github.com/jogi/GTFSModel) - GTFS data models and database schema
- [GRDB](https://github.com/groue/GRDB.swift) - SQLite toolkit
- [ArgumentParser](https://github.com/apple/swift-argument-parser) - CLI argument parsing
- [CSV.swift](https://github.com/yaslab/CSV.swift) - CSV file parsing

## Performance

For typical transit agency feeds (~390K stop_times):
- Import time: ~60 seconds
- Database size: ~40MB

## Documentation

See [CLAUDE.md](CLAUDE.md) for detailed architecture and implementation notes.

## Import results

Invalid rows are reported to stderr and skipped; later valid rows are still imported.
The final summary reports accepted and rejected row counts, with per-file rejection
counts on stderr. Row rejections do not change the successful exit status. Unreadable
required files, CSV stream errors, and database workflow failures still throw errors;
file failures during replacement roll back the feed transaction.

GTFS service-day hours are retained in the database: `24:10:00` remains `24:10:00`,
so clients can filter and sort overnight service correctly. Empty fare `transfers`
values mean unlimited transfers and are stored using GTFSModel's `-1` sentinel.

For paired local changes to this importer and a sibling GTFSModel checkout, use
`swift package edit GTFSModel --path /absolute/path/to/GTFSModel`. Publish the model
changes first, then update and commit the importer's dependency resolution before
releasing the importer. `swift package unedit GTFSModel` removes the local override.
