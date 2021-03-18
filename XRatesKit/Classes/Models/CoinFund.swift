import Foundation
import GRDB

public class CoinFund: Record, Decodable {
    public let id: String
    public let name: String
    public let url: String
    public let category: String

    init(id: String, name: String, url: String, category: String) {
        self.id = id
        self.name = name
        self.url = url
        self.category = category

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_funds"
    }

    enum Columns: String, ColumnExpression {
        case id, name, url, category
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        url = row[Columns.url]
        category = row[Columns.category]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.url] = url
        container[Columns.category] = category
    }

}

class CoinFundCoinInfo: Record {
    let coinFundId: String
    let coinInfoId: String

    init(coinFundId: String, coinInfoId: String) {
        self.coinFundId = coinFundId
        self.coinInfoId = coinInfoId

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_fund_coin_infos"
    }

    enum Columns: String, ColumnExpression {
        case coinFundId, coinInfoId
    }

    required init(row: Row) {
        coinFundId = row[Columns.coinFundId]
        coinInfoId = row[Columns.coinInfoId]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinFundId] = coinFundId
        container[Columns.coinInfoId] = coinInfoId
    }
}
