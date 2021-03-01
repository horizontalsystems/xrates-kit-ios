import HsToolKit
import CoinKit

class CoinGeckoCoinMarketInfoMapper: IApiMapper {
    struct CoinGeckoCoinInfoResponse {
        let rate: Decimal
        let rateHigh24h: Decimal
        let rateLow24h: Decimal
        let totalSupply: Decimal
        let circulatingSupply: Decimal
        let volume24h: Decimal
        let marketCap: Decimal
        let marketCapDiff24h: Decimal
        let description: String
        let rateDiffs: [TimePeriod: [String: Decimal]]
        let links: [LinkType: String]
        let platforms: [CoinPlatformType: String]
    }
    
    private let coinType: CoinType
    private let currencyCode: String
    private let timePeriods: [TimePeriod]
    private let rateDiffCoinCodes: [String]
    
    init(coinType: CoinType, currencyCode: String, timePeriods: [TimePeriod], rateDiffCoinCodes: [String]) {
        self.coinType = coinType
        self.currencyCode = currencyCode
        self.timePeriods = timePeriods
        self.rateDiffCoinCodes = rateDiffCoinCodes
    }
    
    private func fiatValueDecimal(marketData: [String: Any], key: String, currencyCode: String? = nil) -> Decimal {
        guard let values = marketData[key] as? [String: Any],
              let fiatValue = values[currencyCode ?? self.currencyCode],
              let fiatValueDecimal = Decimal(convertibleValue: fiatValue) else {
            return 0
        }
        
        return fiatValueDecimal
    }
    
    func map(statusCode: Int, data: Any?) throws -> CoinGeckoCoinInfoResponse {
        guard let coinMap = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }
        
        guard let marketDataMap = coinMap["market_data"] as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }
        
        let rate = fiatValueDecimal(marketData: marketDataMap, key: "current_price")
        let rateHigh24h = fiatValueDecimal(marketData: marketDataMap, key: "high_24h")
        let rateLow24h = fiatValueDecimal(marketData: marketDataMap, key: "low_24h")
        let totalSupply = Decimal(convertibleValue: marketDataMap["total_supply"]) ?? 0
        let circulatingSupply = Decimal(convertibleValue: marketDataMap["circulating_supply"]) ?? 0
        let volume24h = fiatValueDecimal(marketData: marketDataMap, key: "total_volume")
        let marketCap = fiatValueDecimal(marketData: marketDataMap, key: "market_cap")
        let marketCapDiff24h = Decimal(convertibleValue: marketDataMap["market_cap_change_percentage_24h"]) ?? 0
        
        var description: String = ""
        if let descriptionsMap = coinMap["description"] as? [String: String] {
            description = descriptionsMap["en"] as? String ?? ""
        }
        
        var categories: [String] = coinMap["categories"] as? [String] ?? []
        
        var links = [LinkType: String]()
        if let linksMap = coinMap["links"] as? [String: Any] {
            if let homepages = linksMap["homepage"] as? [String], let firstUrl = homepages.first, !firstUrl.isEmpty {
                links[.website] = firstUrl
            }
            
            if let reddit = linksMap["subreddit_url"] as? String, !reddit.isEmpty {
                links[.reddit] = reddit
            }
            
            if let twitterScreenName = linksMap["twitter_screen_name"] as? String, !twitterScreenName.isEmpty {
                links[.twitter] = "https://twitter.com/\(twitterScreenName)"
            }
            
            if let telegramChannelIdentifier = linksMap["telegram_channel_identifier"] as? String, !telegramChannelIdentifier.isEmpty {
                links[.telegram] = "https://t.me/\(telegramChannelIdentifier)"
            }
            
            if let repos = linksMap["repos_url"] as? [String: Any], let githubUrls = repos["github"] as? [String], let firstUrl = githubUrls.first, !firstUrl.isEmpty {
                links[.github] = firstUrl
            }
        }
        
        var rateDiffs = [TimePeriod: [String: Decimal]]()
        
        for timePeriod in timePeriods {
            var diffs = [String: Decimal]()
            for coinCode in rateDiffCoinCodes {
                diffs[coinCode] = fiatValueDecimal(marketData: marketDataMap, key: "price_change_percentage_\(timePeriod.title)_in_currency", currencyCode: coinCode)
            }
            rateDiffs[timePeriod] = diffs
        }
        
        var platforms = [CoinPlatformType: String]()
        
        if let platform = coinMap["asset_platform_id"] as? String {
            let platformType: CoinPlatformType?
            
            switch platform {
                case "tron": platformType = CoinPlatformType.tron
                case "ethereum": platformType = CoinPlatformType.ethereum
                case "eos": platformType = CoinPlatformType.eos
                case "binance-smart-chain": platformType = CoinPlatformType.binanceSmartChain
                case "binancecoin": platformType = CoinPlatformType.binance
                default: platformType = nil
            }
            
            if let platformType = platformType, let address = coinMap["contract_address"] as? String {
                platforms[platformType] = address
            }
        }
        
        return CoinGeckoCoinInfoResponse(
            rate: rate,
            rateHigh24h: rateHigh24h,
            rateLow24h: rateLow24h,
            totalSupply: totalSupply,
            circulatingSupply: circulatingSupply,
            volume24h: volume24h,
            marketCap: marketCap,
            marketCapDiff24h: marketCapDiff24h,
            description: description,
            rateDiffs: rateDiffs,
            links: links,
            platforms: platforms
        )
    }
    
}
