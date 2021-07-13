import Foundation
import GRDB

public class CoinSecurity: Record {
    let coinId: String
    public let privacy: SecurityLevel
    public let decentralized: Bool
    public let confiscationResistance: Bool
    public let censorshipResistance: Bool

    init(coinId: String, privacy: SecurityLevel, decentralized: Bool, confiscationResistance: Bool, censorshipResistance: Bool) {
        self.coinId = coinId
        self.privacy = privacy
        self.decentralized = decentralized
        self.confiscationResistance = confiscationResistance
        self.censorshipResistance = censorshipResistance

        super.init()
    }

    override open class var databaseTableName: String {
        "coin_securities"
    }

    enum Columns: String, ColumnExpression {
        case coinId, privacy, decentralized, confiscationResistance, censorshipResistance
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        privacy = row[Columns.privacy]
        decentralized = row[Columns.decentralized]
        confiscationResistance = row[Columns.confiscationResistance]
        censorshipResistance = row[Columns.censorshipResistance]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.privacy] = privacy
        container[Columns.decentralized] = decentralized
        container[Columns.confiscationResistance] = confiscationResistance
        container[Columns.censorshipResistance] = censorshipResistance
    }

}
