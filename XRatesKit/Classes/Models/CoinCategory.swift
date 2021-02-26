import Foundation
import GRDB

class CoinCategory: Record, Decodable {
    let id: String
    let name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_categories"
    }

    enum Columns: String, ColumnExpression {
        case id, name
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
    }

}

class CoinCategoryCoinInfo: Record {
    let coinCategoryId: String
    let coinInfoId: String

    init(coinCategoryId: String, coinInfoId: String) {
        self.coinCategoryId = coinCategoryId
        self.coinInfoId = coinInfoId

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_category_coin_infos"
    }

    enum Columns: String, ColumnExpression {
        case coinCategoryId, coinInfoId
    }

    required init(row: Row) {
        coinCategoryId = row[Columns.coinCategoryId]
        coinInfoId = row[Columns.coinInfoId]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCategoryId] = coinCategoryId
        container[Columns.coinInfoId] = coinInfoId
    }
}
