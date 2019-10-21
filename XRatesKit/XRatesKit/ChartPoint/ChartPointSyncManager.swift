import RxSwift

class ChartPointSyncManager {
    private let schedulerFactory: ChartPointSchedulerFactory
    private let chartPointManager: IChartPointManager
    private let latestRateSyncManager: ILatestRateSyncManager

    private var subjects = [ChartPointKey: PublishSubject<[ChartPoint]>]()
    private var schedulers = [ChartPointKey: ChartPointScheduler]()
    private var latestRateDisposables = [ChartPointKey: Disposable]()

    init(schedulerFactory: ChartPointSchedulerFactory, chartPointManager: IChartPointManager, latestRateSyncManager: ILatestRateSyncManager) {
        self.schedulerFactory = schedulerFactory
        self.chartPointManager = chartPointManager
        self.latestRateSyncManager = latestRateSyncManager
    }

    private func subject(key: ChartPointKey) -> PublishSubject<[ChartPoint]> {
        if let subject = subjects[key] {
            return subject
        }

        let subject = PublishSubject<[ChartPoint]>()
        subjects[key] = subject
        return subject
    }

    private func scheduler(key: ChartPointKey) -> ChartPointScheduler {
        if let scheduler = schedulers[key] {
            return scheduler
        }

        let scheduler = schedulerFactory.scheduler(key: key)
        schedulers[key] = scheduler

        let disposable = latestRateSyncManager.latestRateObservable(key: RateKey(coinCode: key.coinCode, currencyCode: key.currencyCode))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] latestRate in
                    self?.chartPointManager.handleUpdated(latestRate: latestRate, key: key)
                })

        latestRateDisposables[key] = disposable

        return scheduler
    }

    private func cleanUp(key: ChartPointKey) {
        if let subject = subjects[key], subject.hasObservers {
            return
        }

        subjects[key] = nil
        schedulers[key] = nil
        latestRateDisposables[key]?.dispose()
        latestRateDisposables[key] = nil
    }

}

extension ChartPointSyncManager: IChartPointSyncManager {

    func chartPointsObservable(key: ChartPointKey) -> Observable<[ChartPoint]> {
        subject(key: key)
                .do(onSubscribed: { [weak self] in
                    self?.scheduler(key: key).schedule()
                }, onDispose: { [weak self] in
                    self?.cleanUp(key: key)
                })
    }

}

extension ChartPointSyncManager: IChartPointManagerDelegate {

    func didUpdate(chartPoints: [ChartPoint], key: ChartPointKey) {
        subjects[key]?.onNext(chartPoints)
    }

}
