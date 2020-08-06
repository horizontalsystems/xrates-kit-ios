import GRDB

public enum ChartType: Int, CaseIterable {
    case day
    case week
    case week2
    case month
    case month3
    case halfYear
    case year
    case year2

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
        expirationInterval * TimeInterval(pointCount)
    }

    var interval: Int {
        switch self {
        case .day: return 30
        case .week: return 4
        case .week2: return 8
        case .month: return 12
        case .month3: return 2
        case .halfYear: return 3
        case .year: return 7
        case .year2: return 14
        }
    }

    var resource: String {
        switch self {
        case .day: return "histominute"
        case .week: return "histohour"
        case .week2: return "histohour"
        case .month: return "histohour"
        case .month3: return "histoday"
        case .halfYear: return "histoday"
        case .year: return "histoday"
        case .year2: return "histoday"
        }
    }

    var pointCount: Int {
        switch self {
        case .day: return 48
        case .week: return 48
        case .week2: return 45
        case .month: return 60
        case .month3: return 45
        case .halfYear: return 60
        case .year: return 52
        case .year2: return 52
        }
    }

}
