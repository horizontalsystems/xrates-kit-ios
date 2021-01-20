import Foundation

public struct MarketInfo {
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

    init(record: MarketInfoRecord, expirationInterval: TimeInterval) {
        currencyCode = record.coinCurrency
        rate = record.rate
        rateOpenDay = record.rateOpenDay
        rateDiff = record.rateDiff
        volume = record.volume
        marketCap = record.marketCap
        supply = record.supply
        liquidity = record.liquidity
        rateDiffPeriod = record.rateDiffPeriod
        timestamp = record.timestamp

        self.expirationInterval = expirationInterval
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - timestamp > expirationInterval
    }

}
