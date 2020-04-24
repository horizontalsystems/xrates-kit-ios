import RxSwift

class TopMarketsSyncManager {
    private let schedulerFactory: TopMarketsSchedulerFactory

    private var currencyCode: String
    private var subscriptionsCount = 0
    let subject = PublishSubject<[TopMarketInfo]>()

    private var scheduler: IMarketInfoScheduler?
    private let queue = DispatchQueue(label: "io.horizontalsystems.x_rates_kit.top_markets_sync_manager", qos: .userInitiated)

    init(currencyCode: String, schedulerFactory: TopMarketsSchedulerFactory) {
        self.currencyCode = currencyCode
        self.schedulerFactory = schedulerFactory
    }

    private func updateScheduler() {
        scheduler = nil

        guard subscriptionsCount > 0 else {
            return
        }

        scheduler = schedulerFactory.scheduler(currencyCode: currencyCode)
        scheduler?.schedule()
    }

}

extension TopMarketsSyncManager: ITopMarketsSyncManager {

    func set(currencyCode: String) {
        self.currencyCode = currencyCode
        updateScheduler()
    }

    func refresh() {
        scheduler?.forceSchedule()
    }

    func topMarketsObservable() -> Observable<[TopMarketInfo]> {
        subject
                .do(
                        onSubscribed: { [weak self] in
                            guard let _self = self else {
                                return
                            }

                            _self.subscriptionsCount = _self.subscriptionsCount + 1

                            if _self.subscriptionsCount == 1 {
                                _self.updateScheduler()
                            }
                        },
                        onDispose: { [weak self] in
                            guard let _self = self else {
                                return
                            }

                            _self.subscriptionsCount = _self.subscriptionsCount - 1

                            if _self.subscriptionsCount <= 0 {
                                _self.updateScheduler()
                            }
                        }
                )
                .asObservable()
    }

}

extension TopMarketsSyncManager: ITopMarketsManagerDelegate {

    func didUpdate(topMarketInfos: [TopMarketInfo]) {
        queue.async {
            self.subject.onNext(topMarketInfos)
        }
    }

}
