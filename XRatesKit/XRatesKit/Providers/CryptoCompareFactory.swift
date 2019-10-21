class CryptoCompareFactory {
    private let dateProvider: ICurrentDateProvider

    init(dateProvider: ICurrentDateProvider) {
        self.dateProvider = dateProvider
    }

}

extension CryptoCompareFactory: ICryptoCompareFactory {

    func latestRate(coinCode: String, currencyCode: String, response: CryptoCompareLatestRateResponse) -> RateResponse? {
        guard let currencyResponseMap = response.values[coinCode], let rateValue = currencyResponseMap.values[currencyCode] else {
            return nil
        }
        return RateResponse(coinCode: coinCode, value: rateValue)
    }

    func marketStats(coinCode: String, currencyCode: String, response: CryptoCompareMarketInfoResponse) -> MarketStats? {
        guard let marketInfoMap = response.values[coinCode], let marketInfoValue = marketInfoMap.values[currencyCode] else {
            return nil
        }
        return MarketStats(coinCode: coinCode, currencyCode: currencyCode, date: dateProvider.currentDate, volume: marketInfoValue.volume, marketCap: marketInfoValue.marketCap, supply: marketInfoValue.supply)
    }

    func historicalRate(coinCode: String, currencyCode: String, date: Date, value: Decimal) -> RateResponse {
        RateResponse(coinCode: coinCode, value: value)
    }

}