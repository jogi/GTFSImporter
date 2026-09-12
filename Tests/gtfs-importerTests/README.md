# GTFSImporter Tests

The test suite uses Swift Testing to verify CSV import behavior, stop-time
interpolation, route aggregation, and the command workflow. Tests use isolated
in-memory databases or unique temporary directories and run in parallel.

## Running tests

From the GTFSImporter package root:

```sh
swift test
```

Run a specific suite:

```sh
swift test --filter StopTimeInterpolatorTests
```

Collect code coverage:

```sh
swift test --enable-code-coverage
```

GTFSModel owns its persistence and schema tests. Run them separately from a sibling
checkout, since SwiftPM does not run dependency test suites:

```sh
swift test --package-path ../GTFSModel --enable-code-coverage
```

## Organization

| Directory | Purpose |
| --- | --- |
| `ImportingTests` | Defaults, explicit values, CSV date conversion, rejected rows, time validation, and last-stop selection. |
| `IntegrationTests` | Command options, complete feed imports, optional files, rollback, replacement imports, and route aggregation. |
| `UtilityTests` | Interpolation, service-day time normalization, and deterministic console formatting. |
| `TestUtilities` | Database setup, synthetic CSV fixtures, and temporary-directory helpers. |
| `Fixtures/small` | A self-contained VTA feed bundled for one integration scenario. |
| `testData` | Full reference data, excluded from the test resource bundle. |

Use small synthetic fixtures for individual behaviors. The real-feed integration
test checks that each supported file reaches the correct entity. Model-to-storage
mappings, optional values, date persistence, keys, indexes, and associations belong
in GTFSModel's suite.

## Behavior contracts

### Importing

Malformed rows are logged and skipped; subsequent valid rows still import.
Missing optional files produce empty tables. Missing or unreadable required files
and file-decoding failures abort the transaction and preserve the previous feed,
even when valid rows were read before the failure. Reimporting replaces the
feed atomically, dropping child tables before parents.

### Stop times

Untimed rows and extended GTFS hours remain staging values until interpolation
finishes. Extended hours are then converted to the public model's time-of-day
representation, preserving the duration of intervals that cross midnight.

Interpolation uses distances between stops and surrounding time anchors. Gaps
without surrounding anchors remain unchanged. When the distance between anchors
is zero, interpolated stops use the preceding anchor's time. Existing arrival,
departure, and timepoint values are preserved during interpolation.

Tests assert exact results for unequal distances, midnight crossings, multiple
segments, unbounded gaps, coincident stops, repeated visits, multiple trips, and
repeat execution.

### Route aggregation

Every trip contributes its stops. Route names are deduplicated and sorted, and
recomputing the routes clears stale values.

## Writing tests

- Use Swift Testing's `@Test`, `#expect`, and `#require` APIs.
- Give each test its own database. Close file-backed connections before removing
  their temporary directories.
- Keep tests independent of execution order, working directory, terminal state,
  and process-wide environment changes. Avoid sleeps and serialization workarounds.
- Use `#require` before consuming a prerequisite that may be absent. Compare
  complete collections instead of asserting a count and then indexing unchecked.
- Parameterize variations of the same behavior and use independently specified
  expected values.
- Test behavior owned by these packages. Avoid duplicating integration assertions,
  copying constants into tests, or testing generic SQLite and GRDB behavior.
- Keep machine-dependent timing thresholds out of the unit suite.

Code coverage helps locate untested paths; it does not establish assertion quality.
Review owned source files separately from dependencies, generated runners, and test
helpers. Prioritize meaningful regression protection over a coverage percentage.
