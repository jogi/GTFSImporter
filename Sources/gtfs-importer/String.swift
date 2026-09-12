import Foundation

extension String {
    /// Normalize a GTFS service-day hour for the model's time-of-day formatter.
    /// Reject malformed input instead of trapping while importing a row.
    var sanitizedTimeString: String? {
        let parts = split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 3,
            parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.isASCII && $0.isNumber } }),
            let hour = Int(parts[0]), let minute = Int(parts[1]), let second = Int(parts[2]),
            (0..<60).contains(minute), (0..<60).contains(second)
        else { return nil }
        return "\(hour % 24):\(parts[1]):\(parts[2])"
    }
}
