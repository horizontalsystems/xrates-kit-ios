import GRDB

public enum ChartType: Int, CaseIterable {
    case day
    case week
    case month
    case halfYear
    case year

    var expirationInterval: TimeInterval {
        let multiplier: TimeInterval

        switch resource {
        case "histominute": multiplier = 60 
        case "histohour": multiplier = 60 * 60 
        case "histoday": multiplier = 24 * 60 * 60
        default: multiplier = 60
        }

        return TimeInterval(interval) * multiplier
    }

    var rangeInterval: TimeInterval {
        expirationInterval * TimeInterval(interval * pointCount)
    }

    var interval: Int {
        switch self {
        case .day: return 30
        case .week: return 3
        case .month: return 12
        case .halfYear: return 3
        case .year: return 7
        }
    }

    var resource: String {
        switch self {
        case .day: return "histominute"
        case .week: return "histohour"
        case .month: return "histohour"
        case .halfYear: return "histoday"
        case .year: return "histoday"
        }
    }

    var pointCount: Int {
        switch self {
        case .day: return 48
        case .week: return 56
        case .month: return 60
        case .halfYear: return 60
        case .year: return 52
        }
    }

}
