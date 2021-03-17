import RxSwift
import HsToolKit
import Alamofire
import CoinKit

class CryptoCompareProvider {

    enum HistoricalType: String {
        case minute = "histominute"
        case hour = "histohour"
    }

    let provider = InfoProvider.CryptoCompare

    private let providerCoinsManager: ProviderCoinsManager
    private let networkManager: NetworkManager
    private let apiKey: String?
    private let timeoutInterval: TimeInterval
    private let expirationInterval: TimeInterval
    private let indicatorPointCount: Int

    init(providerCoinsManager: ProviderCoinsManager, networkManager: NetworkManager, apiKey: String?, timeoutInterval: TimeInterval, expirationInterval: TimeInterval, topMarketsCount: Int, indicatorPointCount: Int) {
        self.providerCoinsManager = providerCoinsManager
        self.networkManager = networkManager
        self.apiKey = apiKey
        self.timeoutInterval = timeoutInterval
        self.expirationInterval = expirationInterval
        self.indicatorPointCount = indicatorPointCount
    }

    private func urlAndParams(path: String, parameters: Parameters) -> (String, Parameters) {
        var params = parameters
        if let apiKey = self.apiKey {
            params["apiKey"] = apiKey
        }

        return (provider.baseUrl + path, params)
    }

}

extension CryptoCompareProvider: ILatestRatesProvider {

    func latestRateRecords(coinTypes: [CoinType], currencyCode: String) -> Single<[LatestRateRecord]> {
        guard !coinTypes.isEmpty else {
            return Single.just([])
        }

        let externalIds = coinTypes.compactMap { providerCoinsManager.providerId(coinType: $0, provider: .CryptoCompare) }
        let externalIdsJoined = Array(Set(externalIds)).joined(separator: ",")
        let (url, parameters) = urlAndParams(path: "/data/pricemultifull", parameters: ["fsyms": externalIdsJoined, "tsyms": currencyCode])

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
                    .map { [weak providerCoinsManager] (response: CryptoCompareMarketInfoResponse) -> [LatestRateRecord] in
                        var records = [LatestRateRecord]()

                        for (coinCode, values) in response.values {
                            for (currencyCode, marketInfoResponse) in values {
                                guard let coinTypes = providerCoinsManager?.coinTypes(providerId: coinCode, provider: .CryptoCompare) else {
                                    return []
                                }

                                for coinType in coinTypes {
                                    let record = LatestRateRecord(coinType: coinType, currencyCode: currencyCode, response: marketInfoResponse)
                                    records.append(record)
                                }
                            }
                        }

                        return records
                    }
    }

}

extension CryptoCompareProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        guard let externalId = providerCoinsManager.providerId(coinType: coinType, provider: .CryptoCompare) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        let minuteThreshold: TimeInterval = 60 * 60 * 24 * 7
        let historicalType: HistoricalType = timestamp > Date().timeIntervalSince1970 - minuteThreshold ? .minute : .hour
        let (url, parameters) = urlAndParams(
                path: "/data/v2/\(historicalType.rawValue)",
                parameters: ["fsym": externalId, "tsym": currencyCode, "limit": 1, "toTs": Int(timestamp)]
        )

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
                .map { (response: CryptoCompareHistoricalRateResponse) -> Decimal in
                    response.rateValue
                }
    }

}

extension CryptoCompareProvider: IChartPointProvider {

    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]> {
        let pointCount = key.chartType.pointCount + indicatorPointCount

        return chartPoints(key: key, pointCount: pointCount)
    }

    private func chartPoints(key: ChartInfoKey, points: [ChartPoint] = [], pointCount: Int, toTimestamp: Int? = nil) -> Single<[ChartPoint]> {
        guard let externalId = providerCoinsManager.providerId(coinType: key.coinType, provider: .CryptoCompare) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        var chartPointParams: Parameters = ["fsym": externalId, "tsym": key.currencyCode, "limit": pointCount, "aggregate": key.chartType.interval]
        if let ts = toTimestamp {
            chartPointParams["toTs"] = ts
        }
        let (url, parameters) = urlAndParams(path: "/data/v2/\(key.chartType.resource)", parameters: chartPointParams)

        var points = points

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
                .flatMap { (response: CryptoCompareChartStatsResponse) -> Single<[ChartPoint]> in
                    points.insert(contentsOf: response.chartPoints, at: 0)

                    let remains = pointCount - response.chartPoints.count
                    guard remains > 0 else {
                        return Single.just(points)
                    }

                    let lastTimestamp = Int(response.timeFrom - key.chartType.expirationInterval)
                    return self.chartPoints(key: key, points: points, pointCount: remains, toTimestamp: lastTimestamp)
                }
    }

}

extension CryptoCompareProvider: INewsProvider {

    func newsSingle(latestTimestamp: TimeInterval?) -> Single<CryptoCompareNewsResponse> {
        var newsParams: Parameters = ["excludeCategories": "Sponsored"]
        if let timestamp = latestTimestamp {
            newsParams["lTs"] = Int(timestamp)
        }
        let (url, parameters) = urlAndParams(path: "/data/v2/news/", parameters: newsParams)

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
    }

}

extension CryptoCompareProvider: IFiatXRatesProvider {

    func latestFiatXRates(sourceCurrency: String, targetCurrency: String) -> Single<Decimal> {
        guard sourceCurrency.uppercased() != targetCurrency.uppercased() else {
            return Single.just(1)
        }

        let (url, parameters) = urlAndParams(path: "/data/price", parameters: ["fsym": sourceCurrency, "tsyms": targetCurrency])

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request).map { (rateResponse: CryptoCompareFiatRateResponse) in
            rateResponse.rate
        }
    }

}

extension CryptoCompareProvider {

    class RateLimitRetrier: RequestInterceptor {
        private var attempt = 0

        func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
            let error = NetworkManager.unwrap(error: error)

            if case RequestError.rateLimitExceeded = error {
                completion(resolveResult())
            } else {
                completion(.doNotRetry)
            }
        }

        private func resolveResult() -> RetryResult {
            attempt += 1

            if attempt == 1 { return .retryWithDelay(3) }
            if attempt == 2 { return .retryWithDelay(6) }

            return .doNotRetry
        }

    }

}

extension CryptoCompareProvider {

    enum RequestError: Error {
        case rateLimitExceeded
        case noDataForSymbol
    }

}

extension CryptoCompareProvider: IInfoProvider {

    func initProvider() {}

}
