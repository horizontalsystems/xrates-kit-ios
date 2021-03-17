import Foundation
import CoinKit

public struct MarketInfo {
    public let coinType: CoinType
    public let currencyCode: String
    public let rate: Decimal
    public let rateOpenDay: Decimal
    public let rateDiff: Decimal
    public let volume: Decimal
    public let supply: Decimal
    public let rateDiffPeriod: Decimal
    public let timestamp: TimeInterval
    public let liquidity: Decimal
    public let marketCap: Decimal

    private let expirationInterval: TimeInterval

    init(coinType: CoinType, currencyCode: String, rate: Decimal, rateOpenDay: Decimal, rateDiff: Decimal,
         volume: Decimal, supply: Decimal, rateDiffPeriod: Decimal, timestamp: TimeInterval,
         liquidity: Decimal, marketCap: Decimal, expirationInterval: TimeInterval) {
        self.coinType = coinType
        self.currencyCode = currencyCode
        self.rate = rate
        self.rateOpenDay = rateOpenDay
        self.rateDiff = rateDiff
        self.volume = volume
        self.supply = supply
        self.rateDiffPeriod = rateDiffPeriod
        self.timestamp = timestamp
        self.liquidity = liquidity
        self.marketCap = marketCap

        self.expirationInterval = expirationInterval
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - timestamp > expirationInterval
    }

}
