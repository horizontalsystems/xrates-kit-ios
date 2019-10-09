class XRatesDataSource: IXRatesDataSource {
    var coinCodes: [String]
    var currencyCode: String

    init(coins: [String] = [], currency: String = "") {
        self.coinCodes = coins
        self.currencyCode = currency
    }

}
