import GRDB

class TopMarketInfoRecord: Record {
    let coinCode: String
    let coinName: String
    let currencyCode: String
    let timestamp: TimeInterval
    let rate: Decimal
    let open24Hour: Decimal
    let diff: Decimal
    let volume: Decimal
    let marketCap: Decimal
    let supply: Decimal

    init(coinCode: String, coinName: String, currencyCode: String, response: ResponseMarketInfo) {
        self.coinCode = coinCode
        self.coinName = coinName
        self.currencyCode = currencyCode
        timestamp = Date().timeIntervalSince1970
        rate = response.rate
        open24Hour = response.open24Hour
        diff = response.diff
        volume = response.volume
        marketCap = response.marketCap
        supply = response.supply

        super.init()
    }

    override open class var databaseTableName: String {
        "top_market_info"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, coinName, currencyCode, timestamp, rate, open24Hour, diff, volume, marketCap, supply
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        coinName = row[Columns.coinName]
        currencyCode = row[Columns.currencyCode]
        timestamp = row[Columns.timestamp]
        rate = row[Columns.rate]
        open24Hour = row[Columns.open24Hour]
        diff = row[Columns.diff]
        volume = row[Columns.volume]
        marketCap = row[Columns.marketCap]
        supply = row[Columns.supply]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.coinName] = coinName
        container[Columns.currencyCode] = currencyCode
        container[Columns.timestamp] = timestamp
        container[Columns.rate] = rate
        container[Columns.open24Hour] = open24Hour
        container[Columns.diff] = diff
        container[Columns.volume] = volume
        container[Columns.marketCap] = marketCap
        container[Columns.supply] = supply
    }

}

extension TopMarketInfoRecord: CustomStringConvertible {

    var description: String {
        "TopMarketInfo [coinCode: \(coinCode); coinName: \(coinName); currencyCode: \(currencyCode); timestamp: \(timestamp); rate: \(rate); open24Hour: \(open24Hour); diff: \(diff)]"
    }

}
