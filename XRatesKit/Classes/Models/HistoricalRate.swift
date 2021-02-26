import GRDB
import CoinKit

class HistoricalRate: Record {
    let key: PairKey
    let value: Decimal
    let timestamp: TimeInterval

    init(coinType: CoinType, currencyCode: String, value: Decimal, timestamp: TimeInterval) {
        key = PairKey(coinType: coinType, currencyCode: currencyCode)
        self.value = value
        self.timestamp = timestamp

        super.init()
    }

    override open class var databaseTableName: String {
        "historical_rates"
    }

    enum Columns: String, ColumnExpression {
        case coinId, currencyCode, value, timestamp
    }

    required init(row: Row) {
        let coinId: String = row[Columns.coinId]
        key = PairKey(coinType: CoinType(id: coinId) ?? .unsupported(id: coinId), currencyCode: row[Columns.currencyCode])
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = key.coinType.id
        container[Columns.currencyCode] = key.currencyCode
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
    }

}

extension HistoricalRate: CustomStringConvertible {

    var description: String {
        "HistoricalRate [coinCode: \(key.coinType.id); currencyCode: \(key.currencyCode); value: \(value); timestamp: \(timestamp)]"
    }

}

extension HistoricalRate: Equatable {

    static func ==(lhs: HistoricalRate, rhs: HistoricalRate) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value && lhs.timestamp == rhs.timestamp
    }

}
