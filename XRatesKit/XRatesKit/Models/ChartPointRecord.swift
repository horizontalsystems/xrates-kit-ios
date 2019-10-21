import Foundation
import GRDB

class ChartPointRecord: Record {
    private let key: ChartPointKey
    let chartPoint: ChartPoint

    init(key: ChartPointKey, chartPoint: ChartPoint) {
        self.key = key
        self.chartPoint = chartPoint

        super.init()
    }

    override open class var databaseTableName: String {
        "chart_points"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, chartType, date, value
    }

    required init(row: Row) {
        key = ChartPointKey(coinCode: row[Columns.coinCode], currencyCode: row[Columns.currencyCode], chartType: ChartType(rawValue: row[Columns.chartType]) ?? .day)
        chartPoint = ChartPoint(date: row[Columns.date], value: row[Columns.value])

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = key.coinCode
        container[Columns.currencyCode] = key.currencyCode
        container[Columns.chartType] = key.chartType.rawValue
        container[Columns.date] = chartPoint.date
        container[Columns.value] = chartPoint.value
    }

}
