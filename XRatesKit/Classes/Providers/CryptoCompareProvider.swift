import RxSwift
import RxSwiftExt

class CryptoCompareProvider {

    enum HistoricalType: String {
        case minute = "histominute"
        case hour = "histohour"
    }

    private let disposeBag = DisposeBag()

    private let networkManager: NetworkManager
    private let baseUrl: String
    private let timeoutInterval: TimeInterval

    init(networkManager: NetworkManager, baseUrl: String, timeoutInterval: TimeInterval) {
        self.networkManager = networkManager
        self.baseUrl = baseUrl
        self.timeoutInterval = timeoutInterval
    }

    private func marketInfoUrl(coinCodes: [String], currencyCode: String) -> String {
            let coinList = coinCodes.joined(separator: ",")
            return "\(baseUrl)/data/pricemultifull?fsyms=\(coinList)&tsyms=\(currencyCode)"
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

    private func singleWithRetry<T>(single: Single<T>) -> Single<T> {
        single.asObservable()
                .retry(.exponentialDelayed(maxCount: 3, initial: 3, multiplier: 1), scheduler: ConcurrentDispatchQueueScheduler(qos: .background)) { error in
                    if let error = error as? CryptoCompareError, error == .rateLimitExceeded {
                        return true
                    }
                    return false
                }
                .asSingle()
    }

}

extension CryptoCompareProvider: IMarketInfoProvider {

    func getMarketInfoRecords(coinCodes: [String], currencyCode: String) -> Single<[MarketInfoRecord]> {
        let urlString = marketInfoUrl(coinCodes: coinCodes, currencyCode: currencyCode)

        let single: Single<[MarketInfoRecord]> = networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)
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

//        return singleWithRetry(single: single)
        return single
    }

}

extension CryptoCompareProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        let minuteThreshold: TimeInterval = 60 * 60 * 24 * 7

        let historicalType: HistoricalType = timestamp > Date().timeIntervalSince1970 - minuteThreshold ? .minute : .hour

        let urlString = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: historicalType, timestamp: timestamp)
        let single: Single<CryptoCompareHistoricalRateResponse> = networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)

        return singleWithRetry(single: single)
                .map { $0.rateValue }
    }

}

extension CryptoCompareProvider: IChartPointProvider {

    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]> {
        let urlString = chartStatsUrl(key: key)

        let single: Single<[ChartPoint]> = networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)
                .map { (response: CryptoCompareChartStatsResponse) -> [ChartPoint] in
                    response.chartPoints
                }

        return singleWithRetry(single: single)
    }

}

extension CryptoCompareProvider: INewsProvider {

    func newsSingle(for categories: String, latestTimestamp: TimeInterval?) -> Single<CryptoCompareNewsResponse> {
        let single: Single<CryptoCompareNewsResponse> = networkManager.single(urlString: newsUrl(for: categories, latestTimeStamp: latestTimestamp), httpMethod: .get, timoutInterval: timeoutInterval)

        return singleWithRetry(single: single)
    }

}
