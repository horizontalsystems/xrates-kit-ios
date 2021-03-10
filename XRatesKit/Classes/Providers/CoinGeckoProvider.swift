import Foundation
import HsToolKit
import RxSwift
import Alamofire
import CoinKit

class CoinGeckoProvider {
    private let disposeBag = DisposeBag()
    private let provider = InfoProvider.CoinGecko

    private let providerCoinsManager: ProviderCoinsManager
    private let networkManager: NetworkManager
    private let expirationInterval: TimeInterval
    private let coinsPerPage = 250

    init(providerCoinsManager: ProviderCoinsManager, networkManager: NetworkManager, expirationInterval: TimeInterval) {
        self.providerCoinsManager = providerCoinsManager
        self.networkManager = networkManager
        self.expirationInterval = expirationInterval
    }

    private func marketsRequest(currencyCode: String, fetchDiffPeriod: TimePeriod, pageParams: String = "", coinIdsParams: String = "") -> DataRequest {
        let priceChangePercentage: String
        switch fetchDiffPeriod {
        case .hour24, .dayStart: priceChangePercentage = ""
        default: priceChangePercentage = "&price_change_percentage=\(fetchDiffPeriod.title)"
        }

        let url = "\(provider.baseUrl)/coins/markets?\(coinIdsParams)&vs_currency=\(currencyCode)\(priceChangePercentage)&order=market_cap_desc\(pageParams)"
        return networkManager.session.request(url, method: .get, encoding: JSONEncoding())
    }

}

extension CoinGeckoProvider {

    func globalDefiMarketCap(currencyCode: String) -> Single<Decimal> {
        let url = "\(provider.baseUrl)/global/decentralized_finance_defi"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoDefiMarketCapMapper()
        return networkManager.single(request: request, mapper: mapper)
    }

    func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinGeckoCoinMarketInfoMapper.CoinGeckoCoinInfoResponse> {
        guard let externalId = providerCoinsManager.providerId(coinType: coinType, provider: .CoinGecko) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        let url = "\(provider.baseUrl)/coins/\(externalId)?localization=false&tickers=false&developer_data=false&sparkline=false"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoCoinMarketInfoMapper(coinType: coinType, currencyCode: currencyCode.lowercased(), timePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes.map { $0.lowercased() })
        return networkManager.single(request: request, mapper: mapper)
    }

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int, page: Int = 1) -> Single<[CoinMarket]> {
        let expectedItemsCount = min(coinsPerPage, itemCount)
        let perPage = page > 1 ? coinsPerPage : min(coinsPerPage, itemCount)
        let pageParams = "&per_page=\(perPage)&page=\(page)"

        let request = marketsRequest(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, pageParams: pageParams)
        let mapper = CoinGeckoTopMarketMapper(providerCoinManager: providerCoinsManager, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)

        return networkManager.single(request: request, mapper: mapper)
                .flatMap { [weak self] coinMarkets -> Single<[CoinMarket]> in
                    guard let provider = self else {
                        return Single.just(coinMarkets)
                    }

                    if itemCount <= provider.coinsPerPage, itemCount <= coinMarkets.count {
                        return Single.just(Array(coinMarkets[0..<itemCount]))
                    }

                    var nextItemCount = itemCount
                    if coinMarkets.count < expectedItemsCount {
                        nextItemCount += expectedItemsCount - coinMarkets.count
                    }
                    nextItemCount = nextItemCount - provider.coinsPerPage

                    let single = provider.topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: nextItemCount, page: page + 1)

                    return Single<Int>
                            .timer(.seconds(1), scheduler: SerialDispatchQueueScheduler(qos: .background))
                            .flatMap { _ in single }
                            .map { nextCoinMarkets -> [CoinMarket] in coinMarkets + nextCoinMarkets }
                }
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinTypes: [CoinType]) -> Single<[CoinMarket]> {
        let externalIds = coinTypes.compactMap { providerCoinsManager.providerId(coinType: $0, provider: .CoinGecko) }
        let coinIdParams = externalIds.isEmpty ? "" : "&ids=\(externalIds.joined(separator: ","))"

        let request = marketsRequest(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coinIdsParams: coinIdParams)
        let mapper = CoinGeckoTopMarketMapper(providerCoinManager: providerCoinsManager, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)

        return networkManager.single(request: request, mapper: mapper)
    }

}

extension CoinGeckoProvider: IChartPointProvider {

    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]> {
        guard let externalId = providerCoinsManager.providerId(coinType: key.coinType, provider: .CoinGecko) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }


        let url = "\(provider.baseUrl)/coins/\(externalId)/market_chart?vs_currency=\(key.currencyCode)&days=\(key.chartType.days)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinGeckoMarketChartsMapper())
    }

}
