import GRDB

class TopMarketCoin: Record {
    let code: String
    let title: String
    var position: Int = 0

    init(code: String, title: String) {
        self.code = code
        self.title = title

        super.init()
    }

    override open class var databaseTableName: String {
        "top_market_coin"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case code, title, position
    }

    required init(row: Row) {
        code = row[Columns.code]
        title = row[Columns.title]
        position = row[Columns.position]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.code] = code
        container[Columns.title] = title
        container[Columns.position] = position
    }

}

extension TopMarketCoin: CustomStringConvertible {

    var description: String {
        "TopMarketCoin [code: \(code); title: \(title)]"
    }

}
