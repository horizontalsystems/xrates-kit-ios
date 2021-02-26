import CoinKit

public struct CoinMarketInfo {
    public let coinType: CoinType
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
    public let code: String
    public let name: String

    public let description: String
    public let links: [LinkType: String]
    public let rating: String?
    public let categories: [String]
    public let platforms: [CoinPlatformType: String]
}

public enum CoinPlatformType: String {
    case ethereum
    case binance
    case binanceSmartChain
    case tron
    case eos
}

public enum LinkType: String, CodingKey, CaseIterable {
    case guide
    case website
    case whitepaper
    case twitter
    case telegram
    case reddit
    case github
}
