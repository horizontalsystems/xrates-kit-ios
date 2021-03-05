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
                .flatMap { [weak self] chartPoints in
                    if self?.isChartDataValid(chartType: chartPointKey.chartType, chartPoints: chartPoints) ?? true {
                        return Single.just(chartPoints)
                    } else {
                        return self?.coinGeckoProvider.chartPointsSingle(key: chartPointKey) ?? Single.just([])
                    }
                }
                .catchError { [weak self] error in
                    if let error = error as? ProviderCoinsManager.ExternalIdError, error == .noMatchingCoinId {
                        return self?.coinGeckoProvider.chartPointsSingle(key: chartPointKey) ?? Single.just([])
                    }

                    return Single.error(error)
                }
    }

    private func isChartDataValid(chartType: ChartType, chartPoints: [ChartPoint]) -> Bool {
        guard let lastPoint = chartPoints.last else {
            return false
        }

        if (Date().timeIntervalSince1970 - chartType.rangeInterval > lastPoint.timestamp) {
            return false
        }

        if chartPoints.allSatisfy({ point in point.value == 0 }) {
            return false
        }

        return true
    }

}
