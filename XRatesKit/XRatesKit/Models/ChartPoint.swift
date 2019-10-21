import Foundation

public struct ChartPoint {
    public let date: Date
    public let value: Decimal

    init(date: Date, value: Decimal) {
        self.date = date
        self.value = value
    }
}

extension ChartPoint: Equatable {

    public static func ==(lhs: ChartPoint, rhs: ChartPoint) -> Bool {
        lhs.date == rhs.date && lhs.value == rhs.value
    }

}
