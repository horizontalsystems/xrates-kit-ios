import RxSwift

class CryptoCompareProvider {
    enum HistoricalType: String {
        case minute = "histominute"
        case hour = "histohour"
    }

    private let disposeBag = DisposeBag()

    private let networkManager: NetworkManager
    private let cryptoCompareFactory: ICryptoCompareFactory
    private let baseUrl: String
    private let timeoutInterval: TimeInterval

    init(networkManager: NetworkManager, cryptoCompareFactory: ICryptoCompareFactory, baseUrl: String, timeoutInterval: TimeInterval) {
        self.networkManager = networkManager
        self.cryptoCompareFactory = cryptoCompareFactory
        self.baseUrl = baseUrl
        self.timeoutInterval = timeoutInterval
    }

    private func latestRateUrl(coinCodes: [String], currencyCode: String) -> String {
            let coinList = coinCodes.joined(separator: ",")
            return "\(baseUrl)/data/pricemulti?fsyms=\(coinList)&tsyms=\(currencyCode)"
    }

    private func getRates(coinCodes: [String], currencyCode: String, response: CryptoCompareLatestRateResponse) -> [RateResponse] {
        coinCodes.compactMap { coinCode in
            self.cryptoCompareFactory.latestRate(coinCode: coinCode, currencyCode: currencyCode, response: response)
        }
    }

    private func historicalRateUrl(coinCode: String, currencyCode: String, historicalType: HistoricalType, timestamp: TimeInterval) -> String {
        "\(baseUrl)/data/v2/\(historicalType.rawValue)?fsym=\(coinCode)&tsym=\(currencyCode)&limit=1&toTs=\(Int(timestamp))"
    }

    private func marketInfoUrl(coinCode: String, currencyCode: String) -> String {
        "\(baseUrl)/data/pricemultifull?fsyms=\(coinCode)&tsyms=\(currencyCode)"
    }

    private func chartStatsUrl(key: ChartInfoKey) -> String {
        "\(baseUrl)/data/v2/\(key.chartType.resource)?fsym=\(key.coinCode)&tsym=\(key.currencyCode)&limit=\(key.chartType.pointCount)&aggregate=\(key.chartType.interval)"
    }

}

extension CryptoCompareProvider: ILatestRateProvider {

    func getLatestRates(coinCodes: [String], currencyCode: String) -> Single<[RateResponse]> {
        let urlString = latestRateUrl(coinCodes: coinCodes, currencyCode: currencyCode)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: self.timeoutInterval)
                    .map { [unowned self] (response: CryptoCompareLatestRateResponse) -> [RateResponse] in
                        self.getRates(coinCodes: coinCodes, currencyCode: currencyCode, response: response)
                    }
    }

}

extension CryptoCompareProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<RateResponse> {
        let hourUrlString = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: .hour, timestamp: timestamp)
        let minuteUrlString = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: .minute, timestamp: timestamp)

        let minuteSingle: Single<CryptoCompareHistoricalRateResponse> = networkManager.single(urlString: minuteUrlString, httpMethod: .get, timoutInterval: timeoutInterval)
        let hourSingle: Single<CryptoCompareHistoricalRateResponse> = networkManager.single(urlString: hourUrlString, httpMethod: .get, timoutInterval: timeoutInterval)

        return minuteSingle.flatMap { response -> Single<RateResponse> in
            guard let rateValue = response.rateValue else {
                return Single.error(XRatesErrors.HistoricalRate.noValueForMinute)
            }
            let rate = self.cryptoCompareFactory.historicalRate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp, value: rateValue)
            return Single.just(rate)
        }.catchError { _ in
            hourSingle.flatMap { response -> Single<RateResponse> in
                guard let rateValue = response.rateValue else {
                    return Single.error(XRatesErrors.HistoricalRate.noValueForHour)
                }
                let rate = self.cryptoCompareFactory.historicalRate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp, value: rateValue)
                return Single.just(rate)
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

extension CryptoCompareProvider: IMarketInfoProvider {

    func getMarketInfo(coinCode: String, currencyCode: String) -> Single<MarketInfoRecord> {
        let urlString = marketInfoUrl(coinCode: coinCode, currencyCode: currencyCode)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)
                .flatMap { (response: CryptoCompareMarketInfoResponse) -> Single<MarketInfoRecord> in
                    guard let marketInfoMap = response.values[coinCode], let marketInfoValue = marketInfoMap.values[currencyCode] else {
                        return Single.error(XRatesErrors.MarketInfo.noInfo)
                    }

                    let record = MarketInfoRecord(
                            coinCode: coinCode,
                            currencyCode: currencyCode,
                            timestamp: Date().timeIntervalSince1970,
                            volume: marketInfoValue.volume,
                            marketCap: marketInfoValue.marketCap,
                            supply: marketInfoValue.supply
                    )

                    return Single.just(record)
                }
    }

}
