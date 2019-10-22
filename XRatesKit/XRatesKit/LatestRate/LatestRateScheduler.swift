import RxSwift

class LatestRateScheduler {
    private let bufferInterval: TimeInterval = 5

    private let provider: ILatestRateSchedulerProvider
    private let reachabilityManager: IReachabilityManager
    private var logger: Logger?

    private let disposeBag = DisposeBag()
    private var timerDisposable: Disposable?

    private var syncInProgress = false
    private var expirationNotified = false

    init(provider: ILatestRateSchedulerProvider, reachabilityManager: IReachabilityManager, logger: Logger? = nil) {
        self.provider = provider
        self.reachabilityManager = reachabilityManager
        self.logger = logger

        reachabilityManager.reachabilityObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] reachable in
                    if reachable {
                        self?.autoSchedule()
                    }
                })
                .disposed(by: disposeBag)
    }

    private func sync() {
        notifyExpiration()

        // check if sync process is already running
        guard !syncInProgress else {
            logger?.debug("RATE: Sync already running")
            return
        }

        logger?.debug("RATE: Sync started")

        syncInProgress = true

        provider.syncSingle
                .subscribe(onSuccess: { [weak self] in
                    self?.onSyncSuccess()
                }, onError: { [weak self] _ in
                    self?.onSyncError()
                })
                .disposed(by: disposeBag)
    }

    private func onSyncSuccess() {
        logger?.debug("RATE: Sync success")

        expirationNotified = false

        syncInProgress = false
        schedule()
    }

    private func onSyncError() {
        logger?.debug("RATE: Sync error")

        syncInProgress = false
        schedule(delay: provider.retryInterval)
    }

    private func schedule(delay: TimeInterval) {
        let intDelay = Int(delay.rounded(.up))

        logger?.debug("RATE: Schedule: delay: \(intDelay) sec")

        // invalidate previous timer if exists
        timerDisposable?.dispose()

        // schedule new timer
        timerDisposable = Observable<Int>
                .timer(.seconds(intDelay), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.sync()
                })

        timerDisposable?.disposed(by: disposeBag)
    }

    private func notifyExpiration() {
        guard !expirationNotified else {
            return
        }

        let currentTimestamp = Date().timeIntervalSince1970
        if let lastSuccessSyncTimestamp = provider.lastSyncTimestamp, currentTimestamp - lastSuccessSyncTimestamp < provider.expirationInterval {
            return
        }

        logger?.debug("RATE: Notifying expiration")

        provider.notifyExpiredRates()
        expirationNotified = true
    }

    private func autoSchedule() {
        var delay: TimeInterval = 0

        if let lastSyncTimestamp = provider.lastSyncTimestamp {
            let currentTimestamp = Date().timeIntervalSince1970
            let diff = currentTimestamp - lastSyncTimestamp
            delay = max(0, provider.expirationInterval - bufferInterval - diff)
        }

        schedule(delay: delay)
    }

}

extension LatestRateScheduler: ILatestRateScheduler {

    func schedule() {
        logger?.debug("RATE: Auto schedule")

        DispatchQueue.global(qos: .background).async {
            self.autoSchedule()
        }
    }

    func forceSchedule() {
        logger?.debug("RATE: Force schedule")

        DispatchQueue.global(qos: .background).async {
            self.schedule(delay: 0)
        }
    }

}
