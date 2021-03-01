import GRDB

class ProviderCoinRecord: Record {
    let id: String
    let code: String
    let name: String
    let coingeckoId: String?
    let cryptocompareId: String?

    init(id: String, code: String, name: String, coingeckoId: String?, cryptocompareId: String?) {
        self.id = id
        self.code = code
        self.name = name
        self.coingeckoId = coingeckoId
        self.cryptocompareId = cryptocompareId

        super.init()
    }

    override class var databaseTableName: String {
        "provider_coin_records"
    }

    enum Columns: String, ColumnExpression {
        case id
        case code
        case name
        case coingeckoId
        case cryptocompareId
    }

    required init(row: Row) {
        id = row[Columns.id]
        code = row[Columns.code]
        name = row[Columns.name]
        coingeckoId = row[Columns.coingeckoId]
        cryptocompareId = row[Columns.cryptocompareId]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.code] = code
        container[Columns.name] = name
        container[Columns.coingeckoId] = coingeckoId
        container[Columns.cryptocompareId] = cryptocompareId
    }

}
