import RxSwift

class ChartInfoSyncManager {
    private let schedulerFactory: ChartPointSchedulerFactory
    private let chartInfoManager: IChartInfoManager
    private let marketInfoSyncManager: IMarketInfoSyncManager

    private var subjects = [ChartInfoKey: PublishSubject<ChartInfo>]()
    private var schedulers = [ChartInfoKey: ChartPointScheduler]()
    private var marketInfoDisposables = [ChartInfoKey: Disposable]()

    private var failedKeys = ThreadSafeArray<ChartInfoKey>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.x_rates_kit.chart_info_sync_manager", qos: .userInitiated)

    init(schedulerFactory: ChartPointSchedulerFactory, chartInfoManager: IChartInfoManager, marketInfoSyncManager: IMarketInfoSyncManager) {
        self.schedulerFactory = schedulerFactory
        self.chartInfoManager = chartInfoManager
        self.marketInfoSyncManager = marketInfoSyncManager
    }

    private func subject(key: ChartInfoKey) -> PublishSubject<ChartInfo> {
        if let subject = subjects[key] {
            return subject
        }

        let subject = PublishSubject<ChartInfo>()
        subjects[key] = subject
        return subject
    }

    private func scheduler(key: ChartInfoKey) -> ChartPointScheduler {
        if let scheduler = schedulers[key] {
            return scheduler
        }

        let scheduler = schedulerFactory.scheduler(key: key)
        schedulers[key] = scheduler

        let disposable = marketInfoSyncManager.marketInfoObservable(key: PairKey(coinCode: key.coinCode, currencyCode: key.currencyCode))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] marketInfo in
                    self?.chartInfoManager.handleUpdated(marketInfo: marketInfo, key: key)
                })

        marketInfoDisposables[key] = disposable

        return scheduler
    }

    private func cleanUp(key: ChartInfoKey) {
        if let subject = subjects[key], subject.hasObservers {
            return
        }

        subjects[key] = nil
        schedulers[key] = nil
        marketInfoDisposables[key]?.dispose()
        marketInfoDisposables[key] = nil
    }

    private func onSubscribed(key: ChartInfoKey) {
        queue.async {
            self.scheduler(key: key).schedule()
        }
    }

    private func onDisposed(key: ChartInfoKey) {
        queue.async {
            self.cleanUp(key: key)
        }
    }

}

extension ChartInfoSyncManager: IChartInfoSyncManager {

    func chartInfoObservable(key: ChartInfoKey) -> Observable<ChartInfo> {
        queue.sync {
            guard !failedKeys.contains(key) else {
                return Observable.error(XRatesErrors.ChartInfo.noInfo)
            }

            return subject(key: key)
                    .do(onSubscribed: { [weak self] in
                        self?.onSubscribed(key: key)
                    }, onDispose: { [weak self] in
                        self?.onDisposed(key: key)
                    })
        }
    }

}

extension ChartInfoSyncManager: IChartInfoManagerDelegate {

    func didUpdate(chartInfo: ChartInfo, key: ChartInfoKey) {
        queue.async {
            self.subjects[key]?.onNext(chartInfo)
        }
    }

    func didFoundNoChartInfo(key: ChartInfoKey) {
        queue.async {
            self.failedKeys.append(key)
            self.subjects[key]?.onError(XRatesErrors.ChartInfo.noInfo)
        }
    }

}
