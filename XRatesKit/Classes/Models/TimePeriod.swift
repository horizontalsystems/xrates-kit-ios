import Foundation

public enum TimePeriod: String, CaseIterable {
    case all
    case hour1
    case dayStart
    case hour24
    case day7
    case day14
    case day30
    case day200
    case year1

    public init(chartType: ChartType) {
        switch chartType {
        case .today: self = .dayStart
        case .day: self = .hour24
        case .week: self = .day7
        case .week2: self = .day14
        case .month: self = .day30
        case .halfYear: self = .day200
        case .year: self = .year1
        default: self = .hour24
        }
    }

    public var chartType: ChartType {
        switch self {
        case .dayStart: return .today
        case .hour24: return .day
        case .day7: return .week
        case .day14: return .week2
        case .day30: return .month
        case .day200: return .halfYear
        case .year1: return .year
        default: return .day
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .all: return 0
        case .hour1: return 3600
        case .dayStart: return 0
        case .hour24: return 86400
        case .day7: return 604800
        case .day14: return 1209600
        case .day30: return 2592000
        case .day200: return 17280000
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
        case .day14: return "14d"
        case .day30: return "30d"
        case .day200: return "200d"
        case .year1: return "1y"
        }
    }

}

extension TimePeriod {

    public init(rawValue: String) {
        switch rawValue {
        case "All": self = .all
        case "1h": self =  .hour1
        case "DayStart": self =  .dayStart
        case "24h": self =  .hour24
        case "7d": self =  .day7
        case "14d": self =  .day14
        case "30d": self =  .day30
        case "200d": self =  .day200
        case "1y": self =  .year1
        default: self = .hour24
        }
    }

}
