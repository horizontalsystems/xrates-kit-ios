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
    public let rateDiffPeriod: Decimal?
    public let timestamp: TimeInterval
    public let liquidity: Decimal
    public let marketCap: Decimal
    public let dilutedMarketCap: Decimal?
    public let totalSupply: Decimal?
    public let maxSupply: Decimal?
    public let athChangePercentage: Decimal?
    public let atlChangePercentage: Decimal?

    private let expirationInterval: TimeInterval

    init(coinType: CoinType, currencyCode: String, rate: Decimal, rateOpenDay: Decimal, rateDiff: Decimal,
         volume: Decimal, supply: Decimal, rateDiffPeriod: Decimal?, timestamp: TimeInterval,
         liquidity: Decimal, marketCap: Decimal, dilutedMarketCap: Decimal?, totalSupply: Decimal?, maxSupply: Decimal?,
         athChangePercentage: Decimal?, atlChangePercentage: Decimal?, expirationInterval: TimeInterval) {

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
        self.dilutedMarketCap = dilutedMarketCap
        self.totalSupply = totalSupply
        self.maxSupply = maxSupply
        self.athChangePercentage = athChangePercentage
        self.atlChangePercentage = atlChangePercentage

        self.expirationInterval = expirationInterval
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - timestamp > expirationInterval
    }

}
