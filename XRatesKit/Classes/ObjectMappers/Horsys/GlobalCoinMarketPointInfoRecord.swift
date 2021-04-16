import Foundation
import GRDB

class GlobalCoinMarketPointInfoRecord: Record {
    let currencyCode: String
    let timestamp: TimeInterval
    let timePeriod: TimePeriod

    init(currencyCode: String, timestamp: TimeInterval, timePeriod: TimePeriod) {
        self.currencyCode = currencyCode
        self.timestamp = timestamp
        self.timePeriod = timePeriod

        super.init()
    }

    override open class var databaseTableName: String {
        "global_coin_market_point_info"
    }

    enum Columns: String, ColumnExpression {
        case currencyCode, timestamp, timePeriod
    }

    required init(row: Row) {
        currencyCode = row[Columns.currencyCode]
        timestamp = row[Columns.timestamp]
        timePeriod = TimePeriod(rawValue: row[Columns.timePeriod])

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.currencyCode] = currencyCode
        container[Columns.timestamp] = timestamp
        container[Columns.timePeriod] = timePeriod.title
    }

}
