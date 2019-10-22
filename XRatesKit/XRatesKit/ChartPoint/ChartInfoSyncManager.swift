import RxSwift

class ChartInfoSyncManager {
    private let schedulerFactory: ChartPointSchedulerFactory
    private let chartInfoManager: IChartInfoManager
    private let latestRateSyncManager: ILatestRateSyncManager

    private var subjects = [ChartInfoKey: PublishSubject<ChartInfo?>]()
    private var schedulers = [ChartInfoKey: ChartPointScheduler]()
    private var latestRateDisposables = [ChartInfoKey: Disposable]()

    init(schedulerFactory: ChartPointSchedulerFactory, chartInfoManager: IChartInfoManager, latestRateSyncManager: ILatestRateSyncManager) {
        self.schedulerFactory = schedulerFactory
        self.chartInfoManager = chartInfoManager
        self.latestRateSyncManager = latestRateSyncManager
    }

    private func subject(key: ChartInfoKey) -> PublishSubject<ChartInfo?> {
        if let subject = subjects[key] {
            return subject
        }

        let subject = PublishSubject<ChartInfo?>()
        subjects[key] = subject
        return subject
    }

    private func scheduler(key: ChartInfoKey) -> ChartPointScheduler {
        if let scheduler = schedulers[key] {
            return scheduler
        }

        let scheduler = schedulerFactory.scheduler(key: key)
        schedulers[key] = scheduler

        let disposable = latestRateSyncManager.latestRateObservable(key: RateKey(coinCode: key.coinCode, currencyCode: key.currencyCode))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] latestRate in
                    self?.chartInfoManager.handleUpdated(latestRate: latestRate, key: key)
                })

        latestRateDisposables[key] = disposable

        return scheduler
    }

    private func cleanUp(key: ChartInfoKey) {
        if let subject = subjects[key], subject.hasObservers {
            return
        }

        subjects[key] = nil
        schedulers[key] = nil
        latestRateDisposables[key]?.dispose()
        latestRateDisposables[key] = nil
    }

}

extension ChartInfoSyncManager: IChartInfoSyncManager {

    func chartInfoObservable(key: ChartInfoKey) -> Observable<ChartInfo?> {
        subject(key: key)
                .do(onSubscribed: { [weak self] in
                    self?.scheduler(key: key).schedule()
                }, onDispose: { [weak self] in
                    self?.cleanUp(key: key)
                })
    }

}

extension ChartInfoSyncManager: IChartInfoManagerDelegate {

    func didUpdate(chartInfo: ChartInfo?, key: ChartInfoKey) {
        subjects[key]?.onNext(chartInfo)
    }

}
