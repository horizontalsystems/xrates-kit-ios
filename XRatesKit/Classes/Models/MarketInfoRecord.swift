import GRDB

class MarketInfoRecord: Record {
    var coinCode: String
    let coinCurrency: String
    let rate: Decimal
    let rateOpenDay: Decimal
    let rateDiff: Decimal
    let volume: Decimal
    let supply: Decimal
    let rateDiffPeriod: Decimal
    let timestamp: TimeInterval
    let liquidity: Decimal
    let marketCap: Decimal

    init(coinCode: String, currencyCode: String, rate: Decimal, openDay: Decimal, diff: Decimal, volume: Decimal, marketCap: Decimal, supply: Decimal, liquidity: Decimal = 0, rateDiffPeriod: Decimal = 0) {
        self.coinCode = coinCode
        coinCurrency = currencyCode
        self.rate = rate
        rateOpenDay = openDay
        rateDiff = diff
        self.volume = volume
        self.marketCap = marketCap
        self.supply = supply
        self.liquidity = liquidity
        self.rateDiffPeriod = rateDiffPeriod

        timestamp = Date().timeIntervalSince1970
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
                supply: response.supply,
                liquidity: response.liquidity,
                rateDiffPeriod: response.rateDiffPeriod
        )
    }

    var key: PairKey {
        PairKey(coinCode: coinCode, currencyCode: coinCurrency)
    }

    override open class var databaseTableName: String {
        "market_info"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case coinCode, currencyCode, timestamp, rate, openDay, diff, volume, marketCap, supply, liquidity, rateDiffPeriod
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        coinCurrency = row[Columns.currencyCode]
        timestamp = row[Columns.timestamp]
        rate = row[Columns.rate]
        rateOpenDay = row[Columns.openDay]
        rateDiff = row[Columns.diff]
        volume = row[Columns.volume]
        marketCap = row[Columns.marketCap]
        supply = row[Columns.supply]
        liquidity = row[Columns.liquidity]
        rateDiffPeriod = row[Columns.rateDiffPeriod]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = coinCurrency
        container[Columns.timestamp] = timestamp
        container[Columns.rate] = rate
        container[Columns.openDay] = rateOpenDay
        container[Columns.diff] = rateDiff
        container[Columns.volume] = volume
        container[Columns.marketCap] = marketCap
        container[Columns.supply] = supply
        container[Columns.liquidity] = liquidity
        container[Columns.rateDiffPeriod] = rateDiffPeriod
    }

}

extension MarketInfoRecord: CustomStringConvertible {

    var description: String {
        "MarketInfo [coinCode: \(coinCode); currencyCode: \(coinCurrency); timestamp: \(timestamp); rate: \(rate); openDay: \(rateOpenDay); diff: \(rateDiff)]"
    }

}
