import GRDB

class CoinExternalIdListVersion: Record {
    let id = "coin_external_id_list_version"
    let version: Int

    init(version: Int) {
        self.version = version

        super.init()
    }

    override class var databaseTableName: String {
        "coin_external_id_list_versions"
    }

    enum Columns: String, ColumnExpression {
        case id
        case version
    }

    required init(row: Row) {
        version = row[Columns.version]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.version] = version
    }

}
