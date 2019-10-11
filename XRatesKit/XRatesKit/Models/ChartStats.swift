import GRDB
import Foundation

class ChartStats: Record {

    var coinCode: String
    var currencyCode: String
    var chartType: ChartType
    var timestamp: TimeInterval
    var value: Decimal

    init(coinCode: String, currencyCode: String, chartType: ChartType, timestamp: TimeInterval, value: Decimal) {
        self.coinCode = coinCode
        self.currencyCode = currencyCode
        self.chartType = chartType
        self.timestamp = timestamp
        self.value = value

        super.init()
    }

    override open class var databaseTableName: String {
        "chart_stats"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, chartType, timestamp, value
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        currencyCode = row[Columns.currencyCode]
        chartType = ChartType(rawValue: row[Columns.chartType]) ?? .day
        timestamp = row[Columns.timestamp]
        value = row[Columns.value]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = currencyCode
        container[Columns.chartType] = chartType.rawValue
        container[Columns.timestamp] = timestamp
        container[Columns.value] = value
    }

}
