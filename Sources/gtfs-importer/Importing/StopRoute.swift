import GRDB

struct StopRoute {
    static func addStopRoutes(in db: Database) throws {
        // Use every trip: trips sharing a route/service/shape can visit different stops.
        // Recompute from scratch so removed routes do not leave stale values.
        try db.execute(
            sql: """
                UPDATE stops SET routes = (
                    SELECT GROUP_CONCAT(route_short_name, ', ') FROM (
                        SELECT DISTINCT r.route_short_name
                        FROM stop_times st
                        JOIN trips t ON t.trip_id = st.trip_id
                        JOIN routes r ON r.route_id = t.route_id
                        WHERE st.stop_id = stops.stop_id AND r.route_short_name IS NOT NULL
                        ORDER BY r.route_short_name
                    )
                )
                """)
    }
}
