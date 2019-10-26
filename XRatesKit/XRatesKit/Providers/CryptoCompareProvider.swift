import RxSwift

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

}

extension CryptoCompareProvider: IMarketInfoProvider {

    func getMarketInfoRecords(coinCodes: [String], currencyCode: String) -> Single<[MarketInfoRecord]> {
        let urlString = marketInfoUrl(coinCodes: coinCodes, currencyCode: currencyCode)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)
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

extension CryptoCompareProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        let hourUrlString = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: .hour, timestamp: timestamp)
        let minuteUrlString = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: .minute, timestamp: timestamp)

        let minuteSingle: Single<CryptoCompareHistoricalRateResponse> = networkManager.single(urlString: minuteUrlString, httpMethod: .get, timoutInterval: timeoutInterval)
        let hourSingle: Single<CryptoCompareHistoricalRateResponse> = networkManager.single(urlString: hourUrlString, httpMethod: .get, timoutInterval: timeoutInterval)

        return minuteSingle.flatMap { response -> Single<Decimal> in
            guard let rateValue = response.rateValue else {
                return Single.error(XRatesErrors.HistoricalRate.noValueForMinute)
            }
            return Single.just(rateValue)
        }.catchError { _ in
            hourSingle.flatMap { response -> Single<Decimal> in
                guard let rateValue = response.rateValue else {
                    return Single.error(XRatesErrors.HistoricalRate.noValueForHour)
                }
                return Single.just(rateValue)
            }
        }

    }

}

extension CryptoCompareProvider: IChartPointProvider {

    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]> {
        let urlString = chartStatsUrl(key: key)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)
                .map { (response: CryptoCompareChartStatsResponse) -> [ChartPoint] in
                    response.chartPoints
                }
    }

}
