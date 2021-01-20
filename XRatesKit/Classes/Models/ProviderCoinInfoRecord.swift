import Foundation
import GRDB

class ProviderCoinInfoRecord: Record {
    let code: String
    let providerId: Int
    let providerCoinId: String

    init(code: String, providerId: Int, providerCoinId: String) {
        self.code = code
        self.providerId = providerId
        self.providerCoinId = providerCoinId

        super.init()
    }

    override open class var databaseTableName: String {
        "provider_coin_info"
    }

    enum Columns: String, ColumnExpression {
        case code, providerId, providerCoinId
    }

    required init(row: Row) {
        code = row[Columns.code]
        providerId = row[Columns.providerId]
        providerCoinId = row[Columns.providerCoinId]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.code] = code
        container[Columns.providerId] = providerId
        container[Columns.providerCoinId] = providerCoinId
    }

}
