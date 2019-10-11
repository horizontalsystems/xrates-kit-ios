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

    func marketStats(coinCode: String, currencyCode: String, response: CryptoCompareMarketInfoResponse) -> MarketStats? {
        guard let marketInfoMap = response.values[coinCode], let marketInfoValue = marketInfoMap.values[currencyCode] else {
            return nil
        }
        return MarketStats(coinCode: coinCode, currencyCode: currencyCode, date: dateProvider.currentDate, volume: marketInfoValue.volume, marketCap: marketInfoValue.marketCap, supply: marketInfoValue.supply)
    }

    func historicalRate(coinCode: String, currencyCode: String, date: Date, value: Decimal) -> Rate {
        Rate(coinCode: coinCode, currencyCode: currencyCode, value: value, date: date, isLatest: false)
    }

}