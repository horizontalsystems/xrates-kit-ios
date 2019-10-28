import RxSwift

class MarketInfoScheduler {
    private let bufferInterval: TimeInterval = 5

    private let provider: IMarketInfoSchedulerProvider
    private let reachabilityManager: IReachabilityManager
    private var logger: Logger?

    private let disposeBag = DisposeBag()
    private var timerDisposable: Disposable?

    private var syncInProgress = false
    private var expirationNotified = false

    init(provider: IMarketInfoSchedulerProvider, reachabilityManager: IReachabilityManager, logger: Logger? = nil) {
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
            logger?.debug("MARKET INFO: Sync already running")
            return
        }

        logger?.debug("MARKET INFO: Sync started")

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
        logger?.debug("MARKET INFO: Sync success")

        expirationNotified = false

        syncInProgress = false
        autoSchedule(minDelay: provider.retryInterval)
    }

    private func onSyncError() {
        logger?.debug("MARKET INFO: Sync error")

        syncInProgress = false
        schedule(delay: provider.retryInterval)
    }

    private func schedule(delay: TimeInterval) {
        let intDelay = Int(delay.rounded(.up))

        logger?.debug("MARKET INFO: Schedule: delay: \(intDelay) sec")

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
        if let lastSyncTimestamp = provider.lastSyncTimestamp, currentTimestamp - lastSyncTimestamp < provider.expirationInterval {
            return
        }

        logger?.debug("MARKET INFO: Notifying expiration")

        provider.notifyExpired()
        expirationNotified = true
    }

    private func autoSchedule(minDelay: TimeInterval = 0) {
        var delay: TimeInterval = 0

        if let lastSyncTimestamp = provider.lastSyncTimestamp {
            let currentTimestamp = Date().timeIntervalSince1970
            let diff = currentTimestamp - lastSyncTimestamp
            delay = max(0, provider.expirationInterval - bufferInterval - diff)
        }

        schedule(delay: max(minDelay, delay))
    }

}

extension MarketInfoScheduler: IMarketInfoScheduler {

    func schedule() {
        logger?.debug("MARKET INFO: Auto schedule")

        DispatchQueue.global(qos: .background).async {
            self.autoSchedule()
        }
    }

    func forceSchedule() {
        logger?.debug("MARKET INFO: Force schedule")

        DispatchQueue.global(qos: .background).async {
            self.schedule(delay: 0)
        }
    }

}
