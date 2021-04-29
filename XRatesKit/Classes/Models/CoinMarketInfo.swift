import CoinKit

public struct CoinMarketInfo {
    public let data: CoinData
    public let meta: CoinMeta
    public let currencyCode: String
    public let rate: Decimal?
    public let rateHigh24h: Decimal?
    public let rateLow24h: Decimal?
    public let totalSupply: Decimal?
    public let circulatingSupply: Decimal?
    public let volume24h: Decimal?
    public let marketCap: Decimal?
    public let dilutedMarketCap: Decimal?
    public let marketCapDiff24h: Decimal?
    public let genesisDate: TimeInterval?
    public let defiTvlInfo: DefiTvlInfo?
    public var rateDiffs: [TimePeriod: [String: Decimal]]
    public let tickers: [MarketTicker]
}

public struct MarketTicker {
    public let base: String
    public let target: String
    public let marketName: String
    public let marketImageUrl: String?
    public let rate: Decimal
    public let volume: Decimal
}

public struct CoinData {
    public let coinType: CoinType
    public let code: String
    public let name: String
}

public struct ProviderCoinData {
    public let providerId: String
    public let code: String
    public let name: String
}

public struct CoinMeta {
    public let description: String
    public let links: [LinkType: String]
    public let rating: String?
    public let categories: [String]
    public let fundCategories: [CoinFundCategory]
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
