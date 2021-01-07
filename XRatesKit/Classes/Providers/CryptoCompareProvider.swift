import RxSwift
import HsToolKit
import Alamofire

class CryptoCompareProvider {

    enum HistoricalType: String {
        case minute = "histominute"
        case hour = "histohour"
    }

    private let networkManager: NetworkManager
    private let baseUrl: String
    private let apiKey: String?
    private let timeoutInterval: TimeInterval
    private let expirationInterval: TimeInterval
    private let indicatorPointCount: Int

    init(networkManager: NetworkManager, baseUrl: String, apiKey: String?, timeoutInterval: TimeInterval, expirationInterval: TimeInterval, topMarketsCount: Int, indicatorPointCount: Int) {
        self.networkManager = networkManager
        self.baseUrl = baseUrl
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

        return (baseUrl + path, params)
    }

}

extension CryptoCompareProvider: IMarketInfoProvider {

    func getMarketInfoRecords(coins: [XRatesKit.Coin], currencyCode: String) -> Single<[MarketInfoRecord]> {
        guard !coins.isEmpty else {
            return Single.just([])
        }

        let coinList = coins.map { $0.code }.joined(separator: ",")
        let (url, parameters) = urlAndParams(path: "/data/pricemultifull", parameters: ["fsyms": coinList, "tsyms": currencyCode])

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
                    .map { (response: CryptoCompareMarketInfoResponse) -> [MarketInfoRecord] in
                        var records = [MarketInfoRecord]()

                        for (coinCode, values) in response.values {
                            for (currencyCode, marketInfoResponse) in values {
                                let record = MarketInfoRecord(coinCode: coinCode, currencyCode: currencyCode, response: marketInfoResponse)
                                records.append(record)
                            }
                        }

                        return records
                    }
    }

}

extension CryptoCompareProvider: ITopMarketsProvider {

    func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[TopMarket]> {
        let (url, parameters) = urlAndParams(path: "/data/top/mktcapfull", parameters: ["tsym": currencyCode, "limit": itemCount])
        let expirationInterval = self.expirationInterval

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
                .map { (response: CryptoCompareTopMarketInfosResponse) -> [TopMarket] in
                    var topMarkets = [TopMarket]()

                    guard let values = response.values[currencyCode] else {
                        return []
                    }

                    for value in values {
                        let coin = XRatesKit.Coin(code: value.coin.code, title: value.coin.title)
                        let record = MarketInfoRecord(coinCode: value.coin.code, currencyCode: currencyCode, response: value.marketInfo)
                        let topMarket = TopMarket(coin: coin, record: record, expirationInterval: expirationInterval)

                        topMarkets.append(topMarket)
                    }

                    return topMarkets
                }
    }

}

extension CryptoCompareProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        let minuteThreshold: TimeInterval = 60 * 60 * 24 * 7
        let historicalType: HistoricalType = timestamp > Date().timeIntervalSince1970 - minuteThreshold ? .minute : .hour
        let (url, parameters) = urlAndParams(
                path: "/data/v2/\(historicalType.rawValue)",
                parameters: ["fsym": coinCode, "tsym": currencyCode, "limit": 1, "toTs": Int(timestamp)]
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
        var chartPointParams: Parameters = ["fsym": key.coinCode, "tsym": key.currencyCode, "limit": pointCount, "aggregate": key.chartType.interval]
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
