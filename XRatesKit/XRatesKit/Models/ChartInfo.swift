import Foundation

public struct ChartInfo {
    public let points: [ChartPoint]
    public let startDate: Date
    public let endDate: Date
    public var diff: Decimal?
}
