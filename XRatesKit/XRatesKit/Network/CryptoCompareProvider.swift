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

    private func getRates(from response: CryptoCompareLatestRateResponse, coinCodes: [String], currencyCode: String) -> [Rate] {
        coinCodes.compactMap { coinCode in
            self.cryptoCompareFactory.latestRate(coinCode: coinCode, currencyCode: currencyCode, response: response)
        }
    }

    private func historicalRateUrl(coinCode: String, currencyCode: String, historicalType: HistoricalType, date: Date) -> String {
        "\(baseUrl)/data/v2/\(historicalType.rawValue)?fsym=\(coinCode)&tsym=\(currencyCode)&limit=1&toTs=\(Int(date.timeIntervalSince1970))"
    }

}

extension CryptoCompareProvider: ILatestRateProvider {

    func getLatestRates(coinCodes: [String], currencyCode: String) -> Observable<[Rate]> {
        let urlString = latestRateUrl(coinCodes: coinCodes, currencyCode: currencyCode)

        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: self.timeoutInterval)
                    .map { (response: CryptoCompareLatestRateResponse) -> [Rate] in
                        self.getRates(from: response, coinCodes: coinCodes, currencyCode: currencyCode)
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
