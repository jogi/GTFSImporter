import Foundation

enum TestDataHelper {
    static func smallRealTestDataPath() -> String {
        Bundle.module.resourceURL!.appendingPathComponent("small").path
    }

    /// Three stops at distances 0, 1, and 4 degrees along a meridian.
    /// The middle stop intentionally has no time; optional files are absent.
    static func createMinimalGTFSDataset() throws -> URL {
        let directory = try TemporaryFileHelper.createTemporaryDirectory()
        do {
            let files = [
                "agency.txt":
                    "agency_id,agency_name,agency_url,agency_timezone\nA,Test Transit,https://example.com,America/Los_Angeles",
                "routes.txt": "route_id,route_type,route_short_name\nR,3,Red",
                "calendar.txt":
                    "service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date\nS,1,1,1,1,1,0,0,20240101,20241231",
                "trips.txt": "trip_id,route_id,service_id\nT,R,S",
                "stops.txt":
                    "stop_id,stop_lat,stop_lon,location_type,wheelchair_boarding\nA,0,0,0,0\nB,1,0,0,0\nC,4,0,0,0",
                "stop_times.txt":
                    "trip_id,stop_id,stop_sequence,arrival_time,departure_time\nT,A,1,08:00:00,08:01:00\nT,B,2,,\nT,C,3,08:20:00,08:21:00",
            ]
            for (name, contents) in files {
                try contents.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
            }
            return directory
        } catch {
            TemporaryFileHelper.cleanup(directory: directory)
            throw error
        }
    }
}
