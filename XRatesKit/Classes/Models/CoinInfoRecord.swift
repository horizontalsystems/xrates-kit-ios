import Foundation
import GRDB

class CoinInfoRecord: Record {
    let code: String
    let title: String
    let type: String?

    init(code: String, title: String, type: String?) {
        self.code = code
        self.title = title
        self.type = type

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_info"
    }

    enum Columns: String, ColumnExpression {
        case code, title, type
    }

    required init(row: Row) {
        code = row[Columns.code]
        title = row[Columns.title]
        type = row[Columns.type]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.code] = code
        container[Columns.title] = title
        container[Columns.type] = type
    }

}
