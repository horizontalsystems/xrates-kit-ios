import Foundation
import GRDB

public class GlobalCoinMarketPoint: Record {
    let currencyCode: String
    let timePeriod: TimePeriod
    let timestamp: TimeInterval
    var volume24h: Decimal
    var marketCap: Decimal
    var dominanceBtc: Decimal = 0
    var marketCapDefi: Decimal = 0
    var tvl: Decimal = 0

    init(currencyCode: String, timePeriod: TimePeriod, timestamp: TimeInterval, volume24h: Decimal, marketCap: Decimal, dominanceBtc: Decimal, marketCapDefi: Decimal = 0, tvl: Decimal = 0) {
        self.currencyCode = currencyCode
        self.timePeriod = timePeriod
        self.timestamp = timestamp
        self.volume24h = volume24h
        self.marketCap = marketCap
        self.dominanceBtc = dominanceBtc
        self.marketCapDefi = marketCapDefi
        self.tvl = tvl

        super.init()
    }

    override open class var databaseTableName: String {
        "global_coin_market_points"
    }

    enum Columns: String, ColumnExpression {
        case currencyCode, timePeriod, timestamp, volume24h, marketCap, dominanceBtc, marketCapDefi, tvl
    }

    required init(row: Row) {
        currencyCode = row[Columns.currencyCode]
        timePeriod = TimePeriod(rawValue: row[Columns.timePeriod])
        timestamp = row[Columns.timestamp]
        volume24h = row[Columns.volume24h]
        marketCap = row[Columns.marketCap]
        dominanceBtc = row[Columns.dominanceBtc]
        marketCapDefi = row[Columns.marketCapDefi]
        tvl = row[Columns.tvl]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.currencyCode] = currencyCode
        container[Columns.timePeriod] = timePeriod.title
        container[Columns.timestamp] = timestamp
        container[Columns.volume24h] = volume24h
        container[Columns.marketCap] = marketCap
        container[Columns.dominanceBtc] = dominanceBtc
        container[Columns.marketCapDefi] = marketCapDefi
        container[Columns.tvl] = tvl
    }

}
