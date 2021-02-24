import Foundation
import HsToolKit
import RxSwift
import Alamofire

fileprivate class CoinGeckoProviderCoinInfoMapper: IApiMapper {
    typealias T = [ProviderCoinInfoRecord]

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { tokenData in
            guard let coinId = tokenData["id"] as? String,
                  let coinCode = tokenData["symbol"] as? String else {

                return nil
            }

            return ProviderCoinInfoRecord(code: coinCode.uppercased(), coinId: coinId)
        }
    }

}

fileprivate class CoinGeckoDefiMarketCapMapper: IApiMapper {
    typealias T = Decimal

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let dictionary = data as? [String: Any],
              let defiData = dictionary["data"] as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return Decimal(convertibleValue: defiData["defi_market_cap"]) ?? 0
    }

}

fileprivate class CoinGeckoTopMarketMapper: IApiMapper {
    typealias T = [CoinMarket]

    private let currencyCode: String
    private let fetchDiffPeriod: TimePeriod
    private let expirationInterval: TimeInterval

    init(currencyCode: String, fetchDiffPeriod: TimePeriod, expirationInterval: TimeInterval) {
        self.currencyCode = currencyCode
        self.fetchDiffPeriod = fetchDiffPeriod
        self.expirationInterval = expirationInterval
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { tokenData in
            guard let coinCode = tokenData["symbol"] as? String,
                  let coinTitle = tokenData["name"] as? String,
                  let coinId = tokenData["id"] as? String else {

                return nil
            }

            let rate = Decimal(convertibleValue: tokenData["current_price"]) ?? 0
            let supply = Decimal(convertibleValue: tokenData["circulating_supply"]) ?? 0
            let volume = Decimal(convertibleValue: tokenData["total_volume"]) ?? 0
            let marketCap = Decimal(convertibleValue: tokenData["market_cap"]) ?? 0

            let priceDiffFieldName: String
            switch fetchDiffPeriod {
            case .hour1: priceDiffFieldName = "price_change_percentage_1h_in_currency"
            case .day7: priceDiffFieldName = "price_change_percentage_7d_in_currency"
            case .day30: priceDiffFieldName = "price_change_percentage_30d_in_currency"
            case .year1: priceDiffFieldName = "price_change_percentage_1y_in_currency"
            default: priceDiffFieldName = "price_change_percentage_24h"
            }

            let rateDiffPeriod = Decimal(convertibleValue: tokenData[priceDiffFieldName]) ?? 0
            let rateDiff24h = Decimal(convertibleValue: tokenData["price_change_percentage_24h"]) ?? 0

            let record = MarketInfoRecord(
                    coinId: coinId,
                    coinCode: coinCode.uppercased(),
                    currencyCode: currencyCode,
                    rate: rate,
                    openDay: 0,
                    diff: rateDiff24h,
                    volume: volume,
                    marketCap: marketCap,
                    supply: supply,
                    rateDiffPeriod: rateDiffPeriod
            )

            return CoinMarket(coin: XRatesKit.Coin(code: coinCode.uppercased(), title: coinTitle), record: record, expirationInterval: expirationInterval)
        }
    }

}

fileprivate class CoinGeckoCoinInfoMapper: IApiMapper {
    typealias T = CoinMarketInfo

    private let coinCode: String
    private let currencyCode: String
    private let timePeriods: [TimePeriod]
    private let rateDiffCoinCodes: [String]

    init(coinCode: String, currencyCode: String, timePeriods: [TimePeriod], rateDiffCoinCodes: [String]) {
        self.coinCode = coinCode
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

    func map(statusCode: Int, data: Any?) throws -> T {
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

        var links = [String: String]()
        if let linksMap = coinMap["links"] as? [String: Any] {
            if let homepages = linksMap["homepage"] as? [String], let firstUrl = homepages.first {
                links["website"] = firstUrl
            }

            if let reddit = linksMap["subreddit_url"] as? String {
                links["reddit"] = reddit
            }

            if let twitterScreenName = linksMap["twitter_screen_name"] as? String {
                links["twitter"] = "https://twitter.com/\(twitterScreenName)"
            }

            if let telegramChannelIdentifier = linksMap["telegram_channel_identifier"] as? String {
                links["telegram"] = "https://t.me/\(telegramChannelIdentifier)"
            }

            if let repos = linksMap["repos_url"] as? [String: Any], let githubUrls = repos["github"] as? [String], let firstUrl = githubUrls.first {
                links["github"] = firstUrl
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

        return CoinMarketInfo(
                coinId: coinCode,
                currencyCode: currencyCode,
                rate: rate,
                rateHigh24h: rateHigh24h,
                rateLow24h: rateLow24h,
                totalSupply: totalSupply,
                circulatingSupply: circulatingSupply,
                volume24h: volume24h,
                marketCap: marketCap,
                marketCapDiff24h: marketCapDiff24h,
                info: CoinInfo(description: description, categories: categories, links: links),
                rateDiffs: rateDiffs
        )
    }

}

class CoinGeckoProvider {
    static let providerName = "coingecko"

    private let disposeBag = DisposeBag()
    private let provider = InfoProvider.CoinGecko

    private let networkManager: NetworkManager
    private let expirationInterval: TimeInterval

    init(networkManager: NetworkManager, expirationInterval: TimeInterval) {
        self.networkManager = networkManager
        self.expirationInterval = expirationInterval
    }

    private func allCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int? = nil, coinIds: String? = nil) -> Single<[CoinMarket]> {
        let perPage = itemCount.map { "&per_page=\($0)" } ?? ""

        let priceChangePercentage: String
        switch fetchDiffPeriod {
        case .hour24, .dayStart: priceChangePercentage = ""
        default: priceChangePercentage = "&price_change_percentage=\(fetchDiffPeriod.title)"
        }

        let url = "\(provider.baseUrl)/coins/markets?\(coinIds ?? "")&vs_currency=\(currencyCode)\(priceChangePercentage)&order=market_cap_desc\(perPage)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoTopMarketMapper(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)
        return networkManager.single(request: request, mapper: mapper)
    }

}

extension CoinGeckoProvider {

    func globalDefiMarketCap(currencyCode: String) -> Single<Decimal> {
        let url = "\(provider.baseUrl)/global/decentralized_finance_defi"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoDefiMarketCapMapper()
        return networkManager.single(request: request, mapper: mapper)
    }

    func coinInfosSingle() -> Single<[ProviderCoinInfoRecord]> {
        let url = "\(provider.baseUrl)/coins/list"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinGeckoProviderCoinInfoMapper())
    }

    func coinMarketInfoSingle(coinCode: String, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo> {
        let url = "\(provider.baseUrl)/coins/\(coinCode)?localization=false&tickers=false&developer_data=false&sparkline=false"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoCoinInfoMapper(coinCode: coinCode, currencyCode: currencyCode.lowercased(), timePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes.map { $0.lowercased() })
        return networkManager.single(request: request, mapper: mapper)
    }

}

extension CoinGeckoProvider {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        allCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinIds: String) -> Single<[CoinMarket]> {
        allCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coinIds: coinIds)
    }

}
