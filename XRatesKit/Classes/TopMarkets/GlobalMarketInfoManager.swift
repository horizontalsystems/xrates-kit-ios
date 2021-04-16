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
        globalMarketInfoPoints(currencyCode: currencyCode, timePeriod: timePeriod).map {
            GlobalCoinMarket(currencyCode: currencyCode, points: $0)
        }
    }

    func globalMarketInfoPoints(currencyCode: String, timePeriod: TimePeriod) -> Single<[GlobalCoinMarketPoint]> {
        let currentTimestamp = Date().timeIntervalSince1970

        if let stored = storage.globalMarketPointInfo(currencyCode: currencyCode, timePeriod: timePeriod) {
            if (currentTimestamp - stored.timestamp) < dataLifetimeSeconds {
                return Single.just(stored.points)
            }

            storage.deleteGlobalMarketInfo(currencyCode: currencyCode, timePeriod: timePeriod)
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

                return points
            }
    }

}
