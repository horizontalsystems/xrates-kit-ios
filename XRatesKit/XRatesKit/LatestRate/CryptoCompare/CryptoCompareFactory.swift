class CryptoCompareFactory {
    private let dateProvider: ICurrentDateProvider

    init(dateProvider: ICurrentDateProvider) {
        self.dateProvider = dateProvider
    }

}

extension CryptoCompareFactory: ICryptoCompareFactory {

    func latestRate(coinCode: String, currencyCode: String, response: CryptoCompareLatestRateResponse) -> Rate? {
        guard let currencyResponseMap = response.values[coinCode], let rateValue = currencyResponseMap.values[currencyCode] else {
            return nil
        }
        return Rate(coinCode: coinCode, currencyCode: currencyCode, value: rateValue, date: dateProvider.currentDate, isLatest: true)
    }

    func historicalRate(coinCode: String, currencyCode: String, date: Date, value: Decimal) -> Rate {
        Rate(coinCode: coinCode, currencyCode: currencyCode, value: value, date: date, isLatest: false)
    }

}