import Foundation
import GRDB

public class GlobalCoinMarket: Record {
    public let currencyCode: String
    public let volume24h: Decimal
    public let volume24hDiff24h: Decimal
    public let marketCap: Decimal
    public let marketCapDiff24h: Decimal
    public var btcDominance: Decimal = 0
    public var btcDominanceDiff24h: Decimal = 0
    public var defiMarketCap: Decimal = 0
    public var defiMarketCapDiff24h: Decimal = 0
    public var defiTvl: Decimal = 0
    public var defiTvlDiff24h: Decimal = 0

    init(currencyCode: String, volume24h: Decimal, volume24hDiff24h: Decimal, marketCap: Decimal, marketCapDiff24h: Decimal, btcDominance: Decimal = 0, btcDominanceDiff24h: Decimal = 0, defiMarketCap: Decimal = 0, defiMarketCapDiff24h: Decimal = 0, defiTvl: Decimal = 0, defiTvlDiff24h: Decimal = 0) {
        self.currencyCode = currencyCode
        self.volume24h = volume24h
        self.volume24hDiff24h = volume24hDiff24h
        self.marketCap = marketCap
        self.marketCapDiff24h = marketCapDiff24h
        self.btcDominance = btcDominance
        self.btcDominanceDiff24h = btcDominanceDiff24h
        self.defiMarketCap = defiMarketCap
        self.defiMarketCapDiff24h = defiMarketCapDiff24h
        self.defiTvl = defiTvl
        self.defiTvlDiff24h = defiTvlDiff24h

        super.init()
    }

    override open class var databaseTableName: String {
        "global_market_info"
    }

    enum Columns: String, ColumnExpression {
        case currencyCode, volume24h, volume24hDiff24h, marketCap, marketCapDiff24h, btcDominance, btcDominanceDiff24h, defiMarketCap, defiMarketCapDiff24h, defiTvl, defiTvlDiff24h
    }

    required init(row: Row) {
        currencyCode = row[Columns.currencyCode]
        volume24h = row[Columns.volume24h]
        volume24hDiff24h = row[Columns.volume24hDiff24h]
        marketCap = row[Columns.marketCap]
        marketCapDiff24h = row[Columns.marketCapDiff24h]
        btcDominance = row[Columns.btcDominance]
        btcDominanceDiff24h = row[Columns.btcDominanceDiff24h]
        defiMarketCap = row[Columns.defiMarketCap]
        defiMarketCapDiff24h = row[Columns.defiMarketCapDiff24h]
        defiTvl = row[Columns.defiTvl]
        defiTvlDiff24h = row[Columns.defiTvlDiff24h]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.currencyCode] = currencyCode
        container[Columns.volume24h] = volume24h
        container[Columns.volume24hDiff24h] = volume24hDiff24h
        container[Columns.marketCap] = marketCap
        container[Columns.marketCapDiff24h] = marketCapDiff24h
        container[Columns.btcDominance] = btcDominance
        container[Columns.btcDominanceDiff24h] = btcDominanceDiff24h
        container[Columns.defiMarketCap] = defiMarketCap
        container[Columns.defiMarketCapDiff24h] = defiMarketCapDiff24h
        container[Columns.defiTvl] = defiTvl
        container[Columns.defiTvlDiff24h] = defiTvlDiff24h
    }

}

extension GlobalCoinMarket: CustomStringConvertible {

    public var description: String {
        "GlobalMarketInfo [currencyCode: \(currencyCode); volume24h: \(volume24h); marketCap: \(marketCap)]"
    }

}

extension GlobalCoinMarket: Equatable {

    public static func ==(lhs: GlobalCoinMarket, rhs: GlobalCoinMarket) -> Bool {
        lhs.currencyCode == rhs.currencyCode
    }

}
