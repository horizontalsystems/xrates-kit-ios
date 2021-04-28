import Foundation
import GRDB

public class Exchange: Record, Decodable {
    public let id: String
    public let name: String
    public let imageUrl: String

    override open class var databaseTableName: String {
        "exchanges"
    }

    enum Columns: String, ColumnExpression {
        case id, name, imageUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, name, imageUrl
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        imageUrl = row[Columns.imageUrl]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.imageUrl] = imageUrl
    }

}
