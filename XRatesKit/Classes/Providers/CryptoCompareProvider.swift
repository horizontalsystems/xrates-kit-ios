import RxSwift
import HsToolKit
import Alamofire

class CryptoCompareProvider {

    enum HistoricalType: String {
        case minute = "histominute"
        case hour = "histohour"
    }

    private let disposeBag = DisposeBag()

    private let networkManager: NetworkManager
    private let baseUrl: String
    private let timeoutInterval: TimeInterval
    private let topMarketsCount: Int

    init(networkManager: NetworkManager, baseUrl: String, timeoutInterval: TimeInterval, topMarketsCount: Int) {
        self.networkManager = networkManager
        self.baseUrl = baseUrl
        self.timeoutInterval = timeoutInterval
        self.topMarketsCount = min(100, max(10, topMarketsCount))
    }

    private func marketInfoUrl(coinCodes: [String], currencyCode: String) -> String {
            let coinList = coinCodes.joined(separator: ",")
            return "\(baseUrl)/data/pricemultifull?fsyms=\(coinList)&tsyms=\(currencyCode)"
    }

    private func topMarketInfosUrl(currencyCode: String) -> String {
        "\(baseUrl)/data/top/mktcapfull?&tsym=\(currencyCode)&limit=\(topMarketsCount)"
    }

    private func historicalRateUrl(coinCode: String, currencyCode: String, historicalType: HistoricalType, timestamp: TimeInterval) -> String {
        "\(baseUrl)/data/v2/\(historicalType.rawValue)?fsym=\(coinCode)&tsym=\(currencyCode)&limit=1&toTs=\(Int(timestamp))"
    }

    private func chartStatsUrl(key: ChartInfoKey) -> String {
        "\(baseUrl)/data/v2/\(key.chartType.resource)?fsym=\(key.coinCode)&tsym=\(key.currencyCode)&limit=\(key.chartType.pointCount)&aggregate=\(key.chartType.interval)"
    }

    private func newsUrl(for categories: String, latestTimeStamp: TimeInterval?) -> String {
        var url = "\(baseUrl)/data/v2/news/?categories=\(categories)&excludeCategories=Sponsored"
        if let timestamp = latestTimeStamp {
            url.append("&lTs=\(Int(timestamp))")
        }
        return url
    }

}

extension CryptoCompareProvider: IMarketInfoProvider {

    func getMarketInfoRecords(coinCodes: [String], currencyCode: String) -> Single<[MarketInfoRecord]> {
        let url = marketInfoUrl(coinCodes: coinCodes, currencyCode: currencyCode)

        return networkManager.single(request: networkManager.session.request(url, method: .get, interceptor: RateLimitRetrier()))
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

        return networkManager.single(request: networkManager.session.request(url, method: .get, interceptor: RateLimitRetrier()))
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

        return networkManager.single(request: networkManager.session.request(url, method: .get, interceptor: RateLimitRetrier()))
                .map { (response: CryptoCompareHistoricalRateResponse) -> Decimal in
                    response.rateValue
                }
    }

}

extension CryptoCompareProvider: IChartPointProvider {

    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]> {
        let url = chartStatsUrl(key: key)

        return networkManager.single(request: networkManager.session.request(url, method: .get, interceptor: RateLimitRetrier()))
                .map { (response: CryptoCompareChartStatsResponse) -> [ChartPoint] in
                    response.chartPoints
                }
    }

}

extension CryptoCompareProvider: INewsProvider {

    func newsSingle(for categories: String, latestTimestamp: TimeInterval?) -> Single<CryptoCompareNewsResponse> {
        let url = newsUrl(for: categories, latestTimeStamp: latestTimestamp)

        return networkManager.single(request: networkManager.session.request(url, method: .get, interceptor: RateLimitRetrier()))
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
