import GRDB
import CoinKit

import ObjectMapper

struct ResponseMarketInfo: ImmutableMappable {
    let timestamp: TimeInterval
    let rate: Decimal
    let openDay: Decimal
    let diff: Decimal
    let volume: Decimal
    let marketCap: Decimal
    let supply: Decimal
    let liquidity: Decimal
    let rateDiffPeriod: Decimal

    init(map: Map) throws {
        timestamp = try map.value("LASTUPDATE")
        rate = try map.value("PRICE", using: ResponseMarketInfo.decimalTransform)
        openDay = try map.value("OPENDAY", using: ResponseMarketInfo.decimalTransform)
        diff = try map.value("CHANGEPCTDAY", using: ResponseMarketInfo.decimalTransform)
        volume = try map.value("VOLUME24HOURTO", using: ResponseMarketInfo.decimalTransform)
        marketCap = try map.value("MKTCAP", using: ResponseMarketInfo.decimalTransform)
        supply = try map.value("SUPPLY", using: ResponseMarketInfo.decimalTransform)

        liquidity = 0
        rateDiffPeriod = 0
    }

    private static let decimalTransform: TransformOf<Decimal, Double> = TransformOf(fromJSON: { double -> Decimal? in
        guard let double = double else {
            return nil
        }

        return Decimal(string: "\(double)")
    }, toJSON: { _ in nil })

}

class LatestRateRecord: Record {
    let coinType: CoinType
    let currencyCode: String
    let rate: Decimal
    let rateDiff24h: Decimal
    let timestamp: TimeInterval

    init(coinType: CoinType, currencyCode: String, rate: Decimal, rateDiff24h: Decimal, timestamp: TimeInterval) {
        self.coinType = coinType
        self.currencyCode = currencyCode
        self.rate = rate
        self.rateDiff24h = rateDiff24h
        self.timestamp = timestamp

        super.init()
    }

    convenience init(coinType: CoinType, currencyCode: String, response: ResponseMarketInfo) {
        self.init(
                coinType: coinType,
                currencyCode: currencyCode,
                rate: response.rate,
                rateDiff24h: response.diff,
                timestamp: response.timestamp
        )
    }

    var key: PairKey {
        PairKey(coinType: coinType, currencyCode: currencyCode)
    }

    override open class var databaseTableName: String {
        "latest_rates"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case coinId, currencyCode, rate, rateDiff24h, timestamp
    }

    required init(row: Row) {
        coinType = CoinType(id: row[Columns.coinId])
        currencyCode = row[Columns.currencyCode]
        timestamp = row[Columns.timestamp]
        rate = row[Columns.rate]
        rateDiff24h = row[Columns.rateDiff24h]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinType.id
        container[Columns.currencyCode] = currencyCode
        container[Columns.rate] = rate
        container[Columns.rateDiff24h] = rateDiff24h
        container[Columns.timestamp] = timestamp
    }

}

extension LatestRateRecord: CustomStringConvertible {

    var description: String {
        "MarketInfo [coinType: \(coinType.id); currencyCode: \(currencyCode); timestamp: \(timestamp); rate: \(rate); diff: \(rateDiff24h)]"
    }

}
