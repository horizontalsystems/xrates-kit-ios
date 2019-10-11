class XRatesDataSource: IXRatesDataSource {
    var coinCodes: [String]
    var currencyCode: String

    init(coinCodes: [String] = [], currencyCode: String) {
        self.coinCodes = coinCodes
        self.currencyCode = currencyCode
    }

}
