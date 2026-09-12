# Small VTA fixture

This checked-in feed is a self-contained subset of the full reference data retained in
`../../testData`. The test bundle includes only this subset.

It contains 1 agency, 1 route, 26 stops, 3 calendars, 30 calendar exceptions,
3 fare attributes, 1 fare rule, 2 directions, 958 shape points, 5 trips, and
130 stop times.

One integration test imports this feed to check file-to-entity wiring. Focused tests
use small synthetic CSV rows or database fixtures so each input documents the
behavior it exercises. Do not add edge cases to this real feed merely to reuse it
in unit tests.
