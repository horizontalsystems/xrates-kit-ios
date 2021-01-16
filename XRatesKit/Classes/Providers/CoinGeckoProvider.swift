import Foundation
import HsToolKit
import RxSwift
import Alamofire

fileprivate class CoinGeckoProviderCoinInfoMapper: IApiMapper {
    typealias T = [ProviderCoinInfoRecord]

    private let providerId: Int

    init(providerId: Int) {
        self.providerId = providerId
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { tokenData in
            guard let coinId = tokenData["id"] as? String,
                  let coinCode = tokenData["symbol"] as? String else {

                return nil
            }

            return ProviderCoinInfoRecord(code: coinCode.uppercased(), providerId: providerId, providerCoinId: coinId)
        }
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
                  let coinTitle = tokenData["name"] as? String else {

                return nil
            }

            let rate = Decimal(convertibleValue: tokenData["current_price"]) ?? 0
            let rateOpenDay = Decimal(convertibleValue: tokenData["price_change_24h"]) ?? 0
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
                    coinCode: coinCode.uppercased(),
                    currencyCode: currencyCode,
                    rate: rate, openDay: rateOpenDay,
                    diff: rateDiff24h,
                    volume: volume,
                    marketCap: marketCap,
                    supply: supply,
                    rateDiffPeriod: rateDiffPeriod
            )

            return CoinMarket(coin: XRatesKit.Coin(code: coinCode, title: coinTitle), record: record, expirationInterval: expirationInterval)
        }
    }

}

class CoinGeckoProvider {
    private let disposeBag = DisposeBag()
    private let provider = InfoProvider.CoinGecko

    private let coinInfoManager: CoinInfoManager
    private let networkManager: NetworkManager
    private let expirationInterval: TimeInterval

    init(coinInfoManager: CoinInfoManager, networkManager: NetworkManager, expirationInterval: TimeInterval) {
        self.coinInfoManager = coinInfoManager
        self.networkManager = networkManager
        self.expirationInterval = expirationInterval

        initProvider()
    }

    func initProvider() {
        if !coinInfoManager.providerCoinInfoExist(providerId: provider.rawValue) {
            providerCoinInfoSingle()
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onSuccess: { [weak self] coins in
                        self?.save(providerCoinInfos: coins)
                    })
                    .disposed(by: disposeBag)
        }

    }

    private func coinIds(coins: [XRatesKit.Coin]?) -> String {
        guard let coins = coins, !coins.isEmpty else {
            return ""
        }

        let coinInfos = coinInfoManager.providerCoinInfos(providerId: provider.rawValue, coinCodes: coins.map { $0.code.uppercased() })
        let coinIds = coinInfos.map { $0.providerCoinId }

        return "&ids=\(coinIds.joined(separator: ","))"
    }

    private func allCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int? = nil, coins: [XRatesKit.Coin]? = nil) -> Single<[CoinMarket]> {
        let coinIds = self.coinIds(coins: coins)
        let perPage = itemCount.map { "&per_page=\($0)" } ?? ""

        let priceChangePercentage: String
        switch fetchDiffPeriod {
        case .hour24, .dayStart: priceChangePercentage = ""
        default: priceChangePercentage = "&price_change_percentage=\(fetchDiffPeriod.title)"
        }

        let url = "\(provider.baseUrl)/coins/markets?\(coinIds)&vs_currency=\(currencyCode)\(priceChangePercentage)&order=market_cap_desc\(perPage)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoTopMarketMapper(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)
        return networkManager.single(request: request, mapper: mapper)
    }

    func providerCoinInfoSingle() -> Single<[ProviderCoinInfoRecord]> {
        let url = "\(provider.baseUrl)/coins/list"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinGeckoProviderCoinInfoMapper(providerId: provider.rawValue))
    }

    func save(providerCoinInfos: [ProviderCoinInfoRecord]) {
        coinInfoManager.save(providerCoinInfos: providerCoinInfos)
    }

}

extension CoinGeckoProvider: ICoinMarketsProvider {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        allCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coins: [XRatesKit.Coin]) -> Single<[CoinMarket]> {
        allCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coins: coins)
    }

}
