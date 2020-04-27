import RxSwift

class MarketInfoSyncManager {
    private let schedulerFactory: MarketInfoSchedulerFactory

    private var coinCodes = [String]()
    private var currencyCode: String

    private var subjects = [PairKey: PublishSubject<MarketInfo>]()
    private var currencySubjects = [String: PublishSubject<[String: MarketInfo]>]()
    private var scheduler: IMarketInfoScheduler?

    private let topMarketsSubject = PublishSubject<[MarketInfo]>()
    private var topMarketsSubscriptionsCount = 0

    private let queue = DispatchQueue(label: "io.horizontalsystems.x_rates_kit.market_info_sync_manager", qos: .userInitiated)

    init(currencyCode: String, schedulerFactory: MarketInfoSchedulerFactory) {
        self.currencyCode = currencyCode
        self.schedulerFactory = schedulerFactory
    }

    private func subject(key: PairKey) -> PublishSubject<MarketInfo> {
        if let subject = subjects[key] {
            return subject
        }

        let subject = PublishSubject<MarketInfo>()
        subjects[key] = subject
        return subject
    }

    private func currencySubject(currencyCode: String) -> PublishSubject<[String: MarketInfo]> {
        if let subject = currencySubjects[currencyCode] {
            return subject
        }

        let subject = PublishSubject<[String: MarketInfo]>()
        currencySubjects[currencyCode] = subject
        return subject
    }

    private func updateScheduler() {
        scheduler = nil

        guard !coinCodes.isEmpty else {
            return
        }

        scheduler = schedulerFactory.scheduler(coinCodes: coinCodes, currencyCode: currencyCode)
        addMarketsInfoSyncer()
        if topMarketsSubscriptionsCount > 1 {
            addTopMarketsSyncer()
        }
        scheduler?.schedule()
    }

    private func addMarketsInfoSyncer() {
        scheduler?.syncers["MarketInfo"] = schedulerFactory.marketInfoSyncer(coinCodes: coinCodes, currencyCode: currencyCode)
    }

    private func addTopMarketsSyncer() {
        scheduler?.syncers["TopMarkets"] = schedulerFactory.topMarketsSyncer(currencyCode: currencyCode)
    }

    private func removeTopMarketsSyncer() {
        scheduler?.syncers.removeValue(forKey: "TopMarkets")
    }

    private func topMarketsSubscriptionAdded() {
        topMarketsSubscriptionsCount = topMarketsSubscriptionsCount + 1

        if topMarketsSubscriptionsCount == 1 {
            addTopMarketsSyncer()
            scheduler?.forceSchedule()
        }
    }

    private func topMarketsSubscriptionRemoved() {
        topMarketsSubscriptionsCount = topMarketsSubscriptionsCount - 1

        if topMarketsSubscriptionsCount <= 0 {
            removeTopMarketsSyncer()
        }
    }
}

extension MarketInfoSyncManager: IMarketInfoSyncManager {

    func set(coinCodes: [String]) {
        self.coinCodes = coinCodes
        updateScheduler()
    }

    func set(currencyCode: String) {
        self.currencyCode = currencyCode
        updateScheduler()
    }

    func refresh() {
        scheduler?.forceSchedule()
    }

    func marketInfoObservable(key: PairKey) -> Observable<MarketInfo> {
        queue.sync {
            subject(key: key).asObservable()
        }
    }

    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]> {
        queue.sync {
            currencySubject(currencyCode: currencyCode).asObservable()
        }
    }

    func topMarketsObservable() -> Observable<[MarketInfo]> {
        topMarketsSubject
                .do(
                        onSubscribed: { [weak self] in self?.topMarketsSubscriptionAdded() },
                        onDispose: { [weak self] in self?.topMarketsSubscriptionRemoved() }
                )
                .asObservable()
    }

}

extension MarketInfoSyncManager: IMarketInfoManagerDelegate {

    func didUpdate(marketInfo: MarketInfo, key: PairKey) {
        queue.async {
            self.subjects[key]?.onNext(marketInfo)
        }
    }

    func didUpdate(marketInfos: [String: MarketInfo], currencyCode: String) {
        queue.async {
            self.currencySubjects[currencyCode]?.onNext(marketInfos)
        }
    }

}

extension MarketInfoSyncManager: ITopMarketsManagerDelegate {

    func didUpdate(topMarketInfos: [MarketInfo]) {
        queue.async {
            self.topMarketsSubject.onNext(topMarketInfos)
        }
    }

}
