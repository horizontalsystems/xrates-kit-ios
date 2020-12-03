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
    private let apiKey: String
    private let timeoutInterval: TimeInterval
    private let topMarketsCount: Int
    private let indicatorPointCount: Int

    init(networkManager: NetworkManager, baseUrl: String, apiKey: String?, timeoutInterval: TimeInterval, topMarketsCount: Int, indicatorPointCount: Int) {
        self.networkManager = networkManager
        self.baseUrl = baseUrl
        if let apiKey = apiKey {
            self.apiKey = "api_key=\(apiKey)"
        } else {
            self.apiKey = ""
        }
        self.timeoutInterval = timeoutInterval
        self.topMarketsCount = min(100, max(10, topMarketsCount))
        self.indicatorPointCount = indicatorPointCount
    }

    private func marketInfoUrl(coinCodes: [String], currencyCode: String) -> String {
            let coinList = coinCodes.joined(separator: ",")
            return "\(baseUrl)/data/pricemultifull?\(apiKey)&fsyms=\(coinList)&tsyms=\(currencyCode)"
    }

    private func topMarketInfosUrl(currencyCode: String) -> String {
        "\(baseUrl)/data/top/mktcapfull?\(apiKey)&tsym=\(currencyCode)&limit=\(topMarketsCount)"
    }

    private func historicalRateUrl(coinCode: String, currencyCode: String, historicalType: HistoricalType, timestamp: TimeInterval) -> String {
        "\(baseUrl)/data/v2/\(historicalType.rawValue)?\(apiKey)&fsym=\(coinCode)&tsym=\(currencyCode)&limit=1&toTs=\(Int(timestamp))"
    }

    private func chartStatsUrl(key: ChartInfoKey, pointCount: Int, toTimestamp: Int?) -> String {
        let ts = toTimestamp.map { "&toTs=\($0)" } ?? ""

        return "\(baseUrl)/data/v2/\(key.chartType.resource)?\(apiKey)&fsym=\(key.coinCode)&tsym=\(key.currencyCode)&limit=\(pointCount)&aggregate=\(key.chartType.interval)" + ts
    }

    private func newsUrl(latestTimeStamp: TimeInterval?) -> String {
        var url = "\(baseUrl)/data/v2/news/?\(apiKey)&excludeCategories=Sponsored"
        if let timestamp = latestTimeStamp {
            url.append("&lTs=\(Int(timestamp))")
        }
        return url
    }

    private func fiatRatesUrl(source: String, target: String) -> String {
        "\(baseUrl)/data/price?\(apiKey)&fsym=\(source)&tsyms=\(target)"
    }

}

extension CryptoCompareProvider: IMarketInfoProvider {

    func getMarketInfoRecords(coins: [XRatesKit.Coin], currencyCode: String) -> Single<[MarketInfoRecord]> {
        let url = marketInfoUrl(coinCodes: coins.map { $0.code }, currencyCode: currencyCode)
        let request = networkManager.session
                .request(url, method: .get, interceptor: RateLimitRetrier())
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

    func topMarkets(currencyCode: String) -> Single<[(coin: TopMarketCoin, marketInfo: MarketInfoRecord)]> {
        let url = topMarketInfosUrl(currencyCode: currencyCode)
        let request = networkManager.session
                .request(url, method: .get, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
                .map { (response: CryptoCompareTopMarketInfosResponse) -> [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)] in
                    var topMarkets = [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)]()

                    guard let values = response.values[currencyCode] else {
                        return []
                    }

                    for value in values {
                        let record = MarketInfoRecord(coinCode: value.coin.code, currencyCode: currencyCode, response: value.marketInfo)
                        topMarkets.append((coin: value.coin, marketInfo: record))
                    }

                    return topMarkets
                }
    }

}

extension CryptoCompareProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        let minuteThreshold: TimeInterval = 60 * 60 * 24 * 7

        let historicalType: HistoricalType = timestamp > Date().timeIntervalSince1970 - minuteThreshold ? .minute : .hour

        let url = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: historicalType, timestamp: timestamp)
        let request = networkManager.session
                .request(url, method: .get, interceptor: RateLimitRetrier())
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

        let url = chartStatsUrl(key: key, pointCount: pointCount, toTimestamp: toTimestamp)
        var points = points

        let request = networkManager.session
                .request(url, method: .get, interceptor: RateLimitRetrier())
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
        let url = newsUrl(latestTimeStamp: latestTimestamp)
        let request = networkManager.session
                .request(url, method: .get, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
    }

}

extension CryptoCompareProvider: IFiatXRatesProvider {

    func latestFiatXRates(sourceCurrency: String, targetCurrency: String) -> Single<Decimal> {
        let url = fiatRatesUrl(source: sourceCurrency, target: targetCurrency)

        let request = networkManager.session
                .request(url, method: .get, interceptor: RateLimitRetrier())
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
