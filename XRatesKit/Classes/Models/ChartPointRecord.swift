import Foundation
import GRDB
import CoinKit

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
        case coinId, currencyCode, chartType, timestamp, value, volume
    }

    required init(row: Row) {
        key = ChartInfoKey(coinType: CoinType(id: row[Columns.coinId]), currencyCode: row[Columns.currencyCode], chartType: ChartType(rawValue: row[Columns.chartType]) ?? .day)
        chartPoint = ChartPoint(timestamp: row[Columns.timestamp], value: row[Columns.value], volume: row[Columns.volume])

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = key.coinType.id
        container[Columns.currencyCode] = key.currencyCode
        container[Columns.chartType] = key.chartType.rawValue
        container[Columns.timestamp] = chartPoint.timestamp
        container[Columns.value] = chartPoint.value
        container[Columns.volume] = chartPoint.volume
    }

}
