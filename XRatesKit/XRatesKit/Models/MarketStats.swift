import GRDB

public class MarketStats: Record {

    let coinCode: String
    let currencyCode: String
    let date: Date
    let volume: Decimal
    let marketCap: Decimal
    let supply: Decimal

    init(coinCode: String, currencyCode: String, date: Date, volume: Decimal, marketCap: Decimal, supply: Decimal) {
        self.coinCode = coinCode
        self.currencyCode = currencyCode
        self.date = date
        self.volume = volume
        self.marketCap = marketCap
        self.supply = supply

        super.init()
    }

    override open class var databaseTableName: String {
        "market_stats"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, date, volume, marketCap, supply
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        currencyCode = row[Columns.currencyCode]
        date = row[Columns.date]
        volume = row[Columns.volume]
        marketCap = row[Columns.marketCap]
        supply = row[Columns.supply]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = currencyCode
        container[Columns.date] = date
        container[Columns.volume] = volume
        container[Columns.marketCap] = marketCap
        container[Columns.supply] = supply
    }

}
