import Foundation

public enum TimePeriod: String {
    case all
    case hour1
    case dayStart
    case hour24
    case day7
    case day30
    case year1

    var seconds: TimeInterval {
        switch self {
        case .all: return 0
        case .hour1: return 3600
        case .dayStart: return 0
        case .hour24: return 86400
        case .day7: return 604800
        case .day30: return 2592000
        case .year1: return 31104000
        }
    }

    var title: String {
        switch self {
        case .all: return "All"
        case .hour1: return "1h"
        case .dayStart: return "DayStart"
        case .hour24: return "24h"
        case .day7: return "7d"
        case .day30: return "30d"
        case .year1: return "1y"
        }
    }

}
