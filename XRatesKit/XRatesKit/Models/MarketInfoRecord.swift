import GRDB

public class MarketInfoRecord: Record {
    let coinCode: String
    let currencyCode: String
    let timestamp: TimeInterval
    let volume: Decimal
    let marketCap: Decimal
    let supply: Decimal

    init(coinCode: String, currencyCode: String, timestamp: TimeInterval, volume: Decimal, marketCap: Decimal, supply: Decimal) {
        self.coinCode = coinCode
        self.currencyCode = currencyCode
        self.timestamp = timestamp
        self.volume = volume
        self.marketCap = marketCap
        self.supply = supply

        super.init()
    }

    override open class var databaseTableName: String {
        "market_info"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, timestamp, volume, marketCap, supply
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        currencyCode = row[Columns.currencyCode]
        timestamp = row[Columns.timestamp]
        volume = row[Columns.volume]
        marketCap = row[Columns.marketCap]
        supply = row[Columns.supply]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = currencyCode
        container[Columns.timestamp] = timestamp
        container[Columns.volume] = volume
        container[Columns.marketCap] = marketCap
        container[Columns.supply] = supply
    }

}
