class CryptoCompareFactory {
}

extension CryptoCompareFactory: ICryptoCompareFactory {

    func latestRate(coinCode: String, currencyCode: String, response: CryptoCompareLatestRateResponse) -> RateResponse? {
        guard let currencyResponseMap = response.values[coinCode], let rateValue = currencyResponseMap.values[currencyCode] else {
            return nil
        }
        return RateResponse(coinCode: coinCode, value: rateValue)
    }

    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval, value: Decimal) -> RateResponse {
        RateResponse(coinCode: coinCode, value: value)
    }

}