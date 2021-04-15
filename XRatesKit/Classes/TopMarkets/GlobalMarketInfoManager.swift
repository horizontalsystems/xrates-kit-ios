import RxSwift

class GlobalMarketInfoManager {
    private let dataLifetimeSeconds: TimeInterval = 600 // 6 mins

    private let globalMarketInfoProvider: IGlobalCoinMarketProvider
    private let storage: IGlobalMarketPointInfoStorage

    init(globalMarketInfoProvider: IGlobalCoinMarketProvider, storage: IGlobalMarketPointInfoStorage) {
        self.globalMarketInfoProvider = globalMarketInfoProvider
        self.storage = storage
    }

}

extension GlobalMarketInfoManager {

    func globalMarketInfo(currencyCode: String, timePeriod: TimePeriod) -> Single<GlobalCoinMarket> {
        let currentTimestamp = Date().timeIntervalSince1970

        if let stored = storage.globalMarketPointInfo(currencyCode: currencyCode, timePeriod: timePeriod),
           (currentTimestamp - stored.timestamp) < dataLifetimeSeconds {

            return Single.just(GlobalCoinMarket(currencyCode: currencyCode, points: stored.points))
        }

        return globalMarketInfoProvider
            .globalCoinMarketPoints(currencyCode: currencyCode, timePeriod: timePeriod)
            .map { [weak self] points in

                let globalMarketInfo = GlobalCoinMarketInfo(
                        currencyCode: currencyCode,
                        timestamp: currentTimestamp,
                        timePeriod: timePeriod,
                        points: points)

                self?.storage.saveGlobalMarketInfo(info: globalMarketInfo)

                return GlobalCoinMarket(currencyCode: currencyCode, points: points)
            }
    }

}
