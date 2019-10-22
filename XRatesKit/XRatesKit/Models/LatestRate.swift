import GRDB

class LatestRate: Record {
    let key: RateKey
    let value: Decimal
    let timestamp: TimeInterval

    init(coinCode: String, currencyCode: String, value: Decimal, timestamp: TimeInterval) {
        self.key = RateKey(coinCode: coinCode, currencyCode: currencyCode)
        self.value = value
        self.timestamp = timestamp

        super.init()
    }

    override open class var databaseTableName: String {
        "latest_rates"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, value, timestamp
    }

    required init(row: Row) {
        key = RateKey(coinCode: row[Columns.coinCode], currencyCode: row[Columns.currencyCode])
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = key.coinCode
        container[Columns.currencyCode] = key.currencyCode
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
    }

}

extension LatestRate: CustomStringConvertible {

    var description: String {
        "LatestRate [coinCode: \(key.coinCode); currencyCode: \(key.currencyCode); value: \(value); timestamp: \(timestamp)]"
    }

}

extension LatestRate: Equatable {

    static func ==(lhs: LatestRate, rhs: LatestRate) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value && lhs.timestamp == rhs.timestamp
    }

}
