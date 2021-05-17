import Foundation
import HsToolKit
import RxSwift
import Alamofire
import CoinKit

class CoinGeckoProvider {
    private let disposeBag = DisposeBag()
    private let provider = InfoProvider.coinGecko

    private let providerCoinsManager: ProviderCoinsManager
    private let exchangeStorage: IExchangeStorage
    private let networkManager: ProviderNetworkManager
    private let expirationInterval: TimeInterval
    private let coinsPerPage = 250

    init(providerCoinsManager: ProviderCoinsManager, exchangeStorage: IExchangeStorage, expirationInterval: TimeInterval, logger: Logger) {
        self.providerCoinsManager = providerCoinsManager
        self.exchangeStorage = exchangeStorage
        self.expirationInterval = expirationInterval

        networkManager = ProviderNetworkManager(requestInterval: provider.requestInterval, logger: logger)
    }

    private func marketsRequest(currencyCode: String, fetchDiffPeriod: TimePeriod, category: String? = nil, pageParams: String = "", coinIdsParams: String = "") -> DataRequest {
        let priceChangePercentage: String
        switch fetchDiffPeriod {
        case .hour24, .dayStart: priceChangePercentage = ""
        default: priceChangePercentage = "&price_change_percentage=\(fetchDiffPeriod.title)"
        }

        var categoryParam = ""
        if let category = category {
            categoryParam = "&category=\(category)"
        }

        let url = "\(provider.baseUrl)/coins/markets?\(coinIdsParams)&vs_currency=\(currencyCode)\(priceChangePercentage)\(categoryParam)&order=market_cap_desc\(pageParams)"
        return networkManager.session.request(url, method: .get, encoding: JSONEncoding())
    }

    private var exchangeImageMap: [String: String] {
        exchangeStorage.exchanges.reduce(into: [String: String]()) { $0[$1.id] = $1.imageUrl }
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
        guard let externalId = providerCoinsManager.providerId(coinType: coinType, provider: .coinGecko) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        let url = "\(provider.baseUrl)/coins/\(externalId)?localization=false&tickers=true&developer_data=false&sparkline=false"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoCoinMarketInfoMapper(coinType: coinType, currencyCode: currencyCode.lowercased(), timePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes.map { $0.lowercased() }, exchangeImageMap: exchangeImageMap)
        return networkManager.single(request: request, mapper: mapper)
    }

    private func category(defiFilter: Bool) -> String? {
        defiFilter ? "decentralized_finance_defi" : nil
    }

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int, page: Int = 1, defiFilter: Bool) -> Single<[CoinMarket]> {
        let expectedItemsCount = min(coinsPerPage, itemCount)
        let perPage = page > 1 ? coinsPerPage : min(coinsPerPage, itemCount)
        let pageParams = "&per_page=\(perPage)&page=\(page)"

        let request = marketsRequest(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, category: category(defiFilter: defiFilter), pageParams: pageParams)
        let mapper = CoinGeckoTopMarketMapper(providerCoinManager: providerCoinsManager, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)

        return networkManager.single(request: request, mapper: mapper)
                .flatMap { [weak self] coinMarkets -> Single<[CoinMarket]> in
                    guard let provider = self, coinMarkets.count > 0 else {
                        return Single.just(coinMarkets)
                    }

                    if itemCount <= provider.coinsPerPage || itemCount <= coinMarkets.count {
                        return Single.just(Array(coinMarkets.prefix(itemCount)))
                    }

                    var nextItemCount = itemCount - provider.coinsPerPage
                    if coinMarkets.count < expectedItemsCount {
                        nextItemCount += expectedItemsCount - coinMarkets.count
                    }

                    return provider
                            .topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: nextItemCount, page: page + 1, defiFilter: defiFilter)
                            .map { nextCoinMarkets -> [CoinMarket] in coinMarkets + nextCoinMarkets }
                }
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinTypes: [CoinType], defiFilter: Bool) -> Single<[CoinMarket]> {
        let externalIds = coinTypes.compactMap { providerCoinsManager.providerId(coinType: $0, provider: .coinGecko) }
        let coinIdParams = externalIds.isEmpty ? "" : "&ids=\(externalIds.joined(separator: ","))"

        let request = marketsRequest(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, category: category(defiFilter: defiFilter), coinIdsParams: coinIdParams)
        let mapper = CoinGeckoTopMarketMapper(providerCoinManager: providerCoinsManager, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)

        return networkManager.single(request: request, mapper: mapper)
    }

}

extension CoinGeckoProvider: IChartPointProvider {

    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]> {
        guard let externalId = providerCoinsManager.providerId(coinType: key.coinType, provider: .coinGecko) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        let url = "\(provider.baseUrl)/coins/\(externalId)/market_chart?vs_currency=\(key.currencyCode)&days=\(key.chartType.coinGeckoDaysParameter)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinGeckoMarketChartsMapper(intervalInSeconds: key.chartType.intervalInSeconds))
                .map { points in
                    guard key.chartType.coinGeckoPointCount <= points.count, let last = points.last else {
                        return points
                    }

                    var nextTs = TimeInterval.infinity

                    let hour4: TimeInterval = 4 * 60 * 60
                    let hour8 = 2 * hour4
                    switch key.chartType.intervalInSeconds {
                    case hour4: nextTs = floor(last.timestamp / hour4) * hour4                          // found valid 4h close time
                    case hour8: nextTs = floor(last.timestamp / hour8) * hour8                          // found valid 8h close time
                    default: ()
                    }

                    var lastPoint: ChartPoint?
                    let isAggregate = key.chartType.resource == "histoday"
                    var aggregatedVolume: Decimal = 0

                    var result = [ChartPoint]()

                    for point in points.reversed() {
                        if point.timestamp <= nextTs {                              // we found point with needed timestamp
                            if let lastPoint = lastPoint {                          // if we found new point, we must add last one with aggregated volumes
                                result.append(ChartPoint(timestamp: lastPoint.timestamp, value: lastPoint.value, volume: isAggregate ? aggregatedVolume : nil))
                                aggregatedVolume = 0
                            }

                            lastPoint = point                                       // set last point and start aggregate volumes
                            aggregatedVolume += isAggregate ? point.volume ?? 0 : 0
                            nextTs = point.timestamp - key.chartType.intervalInSeconds
                        } else {
                            aggregatedVolume += isAggregate ? point.volume ?? 0 : 0 // just add volume and drop point
                        }
                    }

                    return result.reversed()
                }
    }
}

extension CoinGeckoProvider: ILatestRatesProvider {

    func latestRateRecords(coinTypes: [CoinType], currencyCode: String) -> Single<[LatestRateRecord]> {
        var coinTypesMap = [String: [CoinType]]()
        for coinType in coinTypes {
            if let providerCoinId = providerCoinsManager.providerId(coinType: coinType, provider: .coinGecko) {
                if coinTypesMap[providerCoinId] == nil {
                    coinTypesMap[providerCoinId] = [coinType]
                } else {
                    coinTypesMap[providerCoinId]?.append(coinType)
                }
            }
        }

        let coinIdsParams = "&ids=\(coinTypesMap.keys.joined(separator: ","))"

        let url = "\(provider.baseUrl)/simple/price?\(coinIdsParams)" +
                        "&vs_currencies=\(currencyCode)&include_market_cap=false" +
                        "&include_24hr_vol=false&include_24hr_change=true&include_last_updated_at=false"

        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinGeckoCoinPriceMapper(coinTypesMap: coinTypesMap, currencyCode: currencyCode))
    }

}

extension CoinGeckoProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        guard let externalId = providerCoinsManager.providerId(coinType: coinType, provider: .coinGecko) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        let currentTime = Date().timeIntervalSince1970
        let startTime, endTime: TimeInterval

        if currentTime - timestamp <= 24 - 10 * 60 {
            startTime = timestamp - 10 * 60
            endTime = timestamp + 10 * 60
        } else {
            startTime = timestamp - 2 * 60 * 60
            endTime = timestamp + 2 * 60 * 60
        }

        let url = "\(provider.baseUrl)/coins/\(externalId)/market_chart/range?vs_currency=\(currencyCode)&from=\(startTime)&to=\(endTime)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinGeckoMarketChartsMapper())
                .map { rates in
                    var nearestTime: TimeInterval?
                    var nearestRate: Decimal = 0

                    for rate in rates {
                        let timeDiff = abs(rate.timestamp - timestamp)

                        if let time = nearestTime {
                            if timeDiff < time {
                                nearestTime = timeDiff
                                nearestRate = rate.value
                            }
                        } else {
                            nearestTime = timeDiff
                            nearestRate = rate.value
                        }
                    }

                    return nearestRate
                }
    }

}

extension CoinGeckoProvider {

    enum RequestError: Error {
        case rateLimitExceeded
        case noDataForSymbol
    }

}
