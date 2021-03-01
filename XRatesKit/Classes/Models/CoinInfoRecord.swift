import Foundation
import GRDB
import CoinKit

class CoinInfoRecord: Record {
    let coinType: CoinType
    let code: String
    let name: String
    let rating: String?
    let description: String?

    init(coinType: CoinType, code: String, name: String, rating: String?, description: String?) {
        self.coinType = coinType
        self.code = code
        self.name = name
        self.rating = rating
        self.description = description

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_info_records"
    }

    enum Columns: String, ColumnExpression {
        case coinId, code, name, rating, description
    }

    required init(row: Row) {
        coinType = CoinType(id: row[Columns.coinId])
        code = row[Columns.code]
        name = row[Columns.name]
        rating = row[Columns.rating]
        description = row[Columns.description]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinType.id
        container[Columns.code] = code
        container[Columns.name] = name
        container[Columns.rating] = rating
        container[Columns.description] = description
    }

}
