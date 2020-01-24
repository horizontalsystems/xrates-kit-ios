import Foundation
import GRDB

class ChartPointRecord: Record {
    private let key: ChartInfoKey
    let chartPoint: ChartPoint

    init(key: ChartInfoKey, chartPoint: ChartPoint) {
        self.key = key
        self.chartPoint = chartPoint

        super.init()
    }

    override open class var databaseTableName: String {
        "chart_points"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, chartType, timestamp, value, volume
    }

    required init(row: Row) {
        key = ChartInfoKey(coinCode: row[Columns.coinCode], currencyCode: row[Columns.currencyCode], chartType: ChartType(rawValue: row[Columns.chartType]) ?? .day)
        chartPoint = ChartPoint(timestamp: row[Columns.timestamp], value: row[Columns.value], volume: row[Columns.volume])

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = key.coinCode
        container[Columns.currencyCode] = key.currencyCode
        container[Columns.chartType] = key.chartType.rawValue
        container[Columns.timestamp] = chartPoint.timestamp
        container[Columns.value] = chartPoint.value
        container[Columns.volume] = chartPoint.volume
    }

}
