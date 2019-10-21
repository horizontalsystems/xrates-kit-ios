import GRDB

class HistoricalRate: Record {
    let key: RateKey
    let value: Decimal
    let date: Date

    init(coinCode: String, currencyCode: String, value: Decimal, date: Date) {
        self.key = RateKey(coinCode: coinCode, currencyCode: currencyCode)
        self.value = value
        self.date = date

        super.init()
    }

    override open class var databaseTableName: String {
        "historical_rates"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, value, date
    }

    required init(row: Row) {
        key = RateKey(coinCode: row[Columns.coinCode], currencyCode: row[Columns.currencyCode])
        value = row[Columns.value]
        date = row[Columns.date]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = key.coinCode
        container[Columns.currencyCode] = key.currencyCode
        container[Columns.value] = value
        container[Columns.date] = date
    }

}

extension HistoricalRate: CustomStringConvertible {

    var description: String {
        "HistoricalRate [coinCode: \(key.coinCode); currencyCode: \(key.currencyCode); value: \(value); date: \(date)]"
    }

}

extension HistoricalRate: Equatable {

    static func ==(lhs: HistoricalRate, rhs: HistoricalRate) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value && lhs.date == rhs.date
    }

}
