import Foundation
import GRDB

class CoinLink: Record {
    let coinInfoId: String
    let linkType: String
    let value: String

    init(coinInfoId: String, linkType: String, value: String) {
        self.coinInfoId = coinInfoId
        self.linkType = linkType
        self.value = value

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_links"
    }

    enum Columns: String, ColumnExpression {
        case coinInfoId, linkType, value
    }

    required init(row: Row) {
        coinInfoId = row[Columns.coinInfoId]
        linkType = row[Columns.linkType]
        value = row[Columns.value]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinInfoId] = coinInfoId
        container[Columns.linkType] = linkType
        container[Columns.value] = value
    }

}
