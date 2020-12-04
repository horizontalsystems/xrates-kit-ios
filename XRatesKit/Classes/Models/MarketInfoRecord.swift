import GRDB

class MarketInfoRecord: Record {
    let coinCode: String
    let coinCurrency: String
    let timestamp: TimeInterval
    let rate: Decimal
    let openDay: Decimal
    let diff: Decimal
    let volume: Decimal
    let marketCap: Decimal
    let supply: Decimal

    init(coinCode: String, currencyCode: String, rate: Decimal, openDay: Decimal, diff: Decimal, volume: Decimal, marketCap: Decimal, supply: Decimal) {
        self.coinCode = coinCode
        coinCurrency = currencyCode
        timestamp = Date().timeIntervalSince1970
        self.rate = rate
        self.openDay = openDay
        self.diff = diff
        self.volume = volume
        self.marketCap = marketCap
        self.supply = supply

        super.init()
    }

    convenience init(coinCode: String, currencyCode: String, response: ResponseMarketInfo) {
        self.init(
                coinCode: coinCode,
                currencyCode: currencyCode,
                rate: response.rate,
                openDay: response.openDay,
                diff: response.diff,
                volume: response.volume,
                marketCap: response.marketCap,
                supply: response.supply
        )
    }

    var key: PairKey {
        PairKey(coinCode: coinCode, currencyCode: coinCurrency)
    }

    override open class var databaseTableName: String {
        "market_info"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case coinCode, currencyCode, timestamp, rate, openDay, diff, volume, marketCap, supply
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        coinCurrency = row[Columns.currencyCode]
        timestamp = row[Columns.timestamp]
        rate = row[Columns.rate]
        openDay = row[Columns.openDay]
        diff = row[Columns.diff]
        volume = row[Columns.volume]
        marketCap = row[Columns.marketCap]
        supply = row[Columns.supply]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = coinCurrency
        container[Columns.timestamp] = timestamp
        container[Columns.rate] = rate
        container[Columns.openDay] = openDay
        container[Columns.diff] = diff
        container[Columns.volume] = volume
        container[Columns.marketCap] = marketCap
        container[Columns.supply] = supply
    }

}

extension MarketInfoRecord: CustomStringConvertible {

    var description: String {
        "MarketInfo [coinCode: \(coinCode); currencyCode: \(coinCurrency); timestamp: \(timestamp); rate: \(rate); openDay: \(openDay); diff: \(diff)]"
    }

}
