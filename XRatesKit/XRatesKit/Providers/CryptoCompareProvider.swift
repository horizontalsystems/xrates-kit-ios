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

    private func getRates(coinCodes: [String], currencyCode: String, response: CryptoCompareLatestRateResponse) -> [Rate] {
        coinCodes.compactMap { coinCode in
            self.cryptoCompareFactory.latestRate(coinCode: coinCode, currencyCode: currencyCode, response: response)
        }
    }

    private func historicalRateUrl(coinCode: String, currencyCode: String, historicalType: HistoricalType, date: Date) -> String {
        "\(baseUrl)/data/v2/\(historicalType.rawValue)?fsym=\(coinCode)&tsym=\(currencyCode)&limit=1&toTs=\(Int(date.timeIntervalSince1970))"
    }

    private func marketInfoUrl(coinCodes: [String], currencyCode: String) -> String {
        let coinList = coinCodes.joined(separator: ",")
        return "\(baseUrl)/data/pricemultifull?fsyms=\(coinList)&tsyms=\(currencyCode)"
    }

    private func getMarketStats(coinCodes: [String], currencyCode: String, response: CryptoCompareMarketInfoResponse) -> [MarketStats] {
        coinCodes.compactMap { coinCode in
            self.cryptoCompareFactory.marketStats(coinCode: coinCode, currencyCode: currencyCode, response: response)
        }
    }

    private func chartStatsUrl(coinCode: String, currencyCode: String, chartType: ChartType) -> String {
        "\(baseUrl)/data/v2/\(chartType.resource)?fsym=\(coinCode)&tsym=\(currencyCode)&limit=\(chartType.pointCount)&aggregate=\(chartType.interval)"
    }

}

extension CryptoCompareProvider: ILatestRateProvider {

    func getLatestRates(coinCodes: [String], currencyCode: String) -> Observable<[Rate]> {
        let urlString = latestRateUrl(coinCodes: coinCodes, currencyCode: currencyCode)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: self.timeoutInterval)
                    .map { (response: CryptoCompareLatestRateResponse) -> [Rate] in
                        self.getRates(coinCodes: coinCodes, currencyCode: currencyCode, response: response)
                    }
                    .asObservable()
    }

}

extension CryptoCompareProvider: IHistoricalRateProvider {

    func getHistoricalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Rate> {
        let hourUrlString = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: .hour, date: date)
        let minuteUrlString = historicalRateUrl(coinCode: coinCode, currencyCode: currencyCode, historicalType: .minute, date: date)

        let minuteSingle: Single<CryptoCompareHistoricalRateResponse> = networkManager.single(urlString: minuteUrlString, httpMethod: .get, timoutInterval: timeoutInterval)
        let hourSingle: Single<CryptoCompareHistoricalRateResponse> = networkManager.single(urlString: hourUrlString, httpMethod: .get, timoutInterval: timeoutInterval)

        return minuteSingle.flatMap { response -> Single<Rate> in
            guard let rateValue = response.rateValue else {
                return Single.error(XRatesErrors.HistoricalRate.noValueForMinute)
            }
            let rate = self.cryptoCompareFactory.historicalRate(coinCode: coinCode, currencyCode: currencyCode, date: date, value: rateValue)
            return Single.just(rate)
        }.catchError { _ in
            hourSingle.flatMap { response -> Single<Rate> in
                guard let rateValue = response.rateValue else {
                    return Single.error(XRatesErrors.HistoricalRate.noValueForHour)
                }
                let rate = self.cryptoCompareFactory.historicalRate(coinCode: coinCode, currencyCode: currencyCode, date: date, value: rateValue)
                return Single.just(rate)
            }
        }

    }

}

extension CryptoCompareProvider: IChartStatsProvider {

    func getChartStats(coinCode: String, currencyCode: String, chartType: ChartType) -> Single<[ChartStats]> {
        let urlString = chartStatsUrl(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: self.timeoutInterval)
                .map { (response: CryptoCompareChartStatsResponse) -> [ChartStats] in
                    response.chartPoints.map { ChartStats(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType, timestamp: $0.timestamp, value: $0.value) }
                }
    }

    func getMarketStats(coinCodes: [String], currencyCode: String) -> Single<[MarketStats]> {
        let urlString = marketInfoUrl(coinCodes: coinCodes, currencyCode: currencyCode)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: self.timeoutInterval)
                .map { (response: CryptoCompareMarketInfoResponse) -> [MarketStats] in
                    self.getMarketStats(coinCodes: coinCodes, currencyCode: currencyCode, response: response)
                }
    }

}