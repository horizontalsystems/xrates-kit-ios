import RxSwift

class BaseChartInfoProvider {
    private let cryptoCompareProvider: CryptoCompareProvider
    private let coinGeckoProvider: CoinGeckoProvider

    init(cryptoCompareProvider: CryptoCompareProvider, coinGeckoProvider: CoinGeckoProvider) {
        self.cryptoCompareProvider = cryptoCompareProvider
        self.coinGeckoProvider = coinGeckoProvider
    }

}

extension BaseChartInfoProvider: IChartPointProvider {

    func chartPointsSingle(key chartPointKey: ChartInfoKey) -> Single<[ChartPoint]> {
        cryptoCompareProvider.chartPointsSingle(key: chartPointKey)
                .catchError { [weak self] error in
                    if let error = error as? ProviderCoinsManager.ExternalIdError, error == .noMatchingCoinId {
                        return self?.coinGeckoProvider.chartPointsSingle(key: chartPointKey) ?? Single.just([])
                    }

                    return Single.error(error)
                }
    }

}
