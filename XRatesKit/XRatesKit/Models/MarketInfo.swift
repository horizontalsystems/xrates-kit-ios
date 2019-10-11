import Foundation

public struct MarketInfo {
    public let coinCode: String
    public let currencyCode: String
    public let volume: Decimal
    public let marketCap: Decimal
    public let supply: Decimal

    init(_ marketStats: MarketStats) {
        self.coinCode = marketStats.coinCode
        self.currencyCode = marketStats.currencyCode
        self.volume = marketStats.volume
        self.marketCap = marketStats.marketCap
        self.supply = marketStats.supply
    }

}
