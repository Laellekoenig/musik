import Foundation

extension TimeInterval {
    /// "3:07", or "1:02:05" for an hour or more.
    var formattedDuration: String {
        let duration = Duration.seconds(isFinite ? Swift.max(0, self) : 0)
        return duration.formatted(.time(pattern: self >= 3600 ? .hourMinuteSecond : .minuteSecond))
    }
}
