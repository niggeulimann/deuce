import Foundation

enum Format {
    /// "1m 12s" / "48s" / "1h 03m" for a duration in seconds.
    static func duration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded())
        if s >= 3600 { return "\(s / 3600)h \(String(format: "%02dm", (s % 3600) / 60))" }
        if s >= 60   { return "\(s / 60)m \(s % 60)s" }
        return "\(s)s"
    }

    static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
