import Foundation
import GRDB

public class CoinFundCategory: Record, Decodable {
    public let id: String
    public let name: String
    public let order: Int
    public var funds = [CoinFund]()

    init(id: String, name: String, order: Int) {
        self.id = id
        self.name = name
        self.order = order

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_fund_categories"
    }

    enum Columns: String, ColumnExpression {
        case id, name, order
    }

    enum CodingKeys: String, CodingKey {
        case id, name, order
    }

    required init(row: Row) {
        id = row[Columns.id]
        name = row[Columns.name]
        order = row[Columns.order]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.order] = order
    }

}
