import Foundation
import GRDB

class ProviderCoinInfoRecord: Record {
    let code: String
    let coinId: String

    init(code: String, coinId: String) {
        self.code = code
        self.coinId = coinId

        super.init()
    }

    override open class var databaseTableName: String {
        "provider_coin_info"
    }

    enum Columns: String, ColumnExpression {
        case code, coinId
    }

    required init(row: Row) {
        code = row[Columns.code]
        coinId = row[Columns.coinId]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.code] = code
        container[Columns.coinId] = coinId
    }

}
