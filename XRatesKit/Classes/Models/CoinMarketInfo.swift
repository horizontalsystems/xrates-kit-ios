public struct CoinMarketInfo {
    public let coinId: String
    public let currencyCode: String
    public let rate: Decimal
    public let rateHigh24h: Decimal
    public let rateLow24h: Decimal
    public let totalSupply: Decimal
    public let circulatingSupply: Decimal
    public let volume24h: Decimal
    public let marketCap: Decimal
    public let marketCapDiff24h: Decimal
    public let info: CoinInfo
    public var rateDiffs: [TimePeriod: [String: Decimal]]
}

public struct CoinInfo {
    public let description: String
    public let categories: [String]
    public let links: [String: String]
}
