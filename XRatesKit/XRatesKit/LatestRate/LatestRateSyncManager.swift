import RxSwift

class LatestRateSyncManager {
    private let schedulerFactory: LatestRateSchedulerFactory

    private var coinCodes = [String]()
    private var currencyCode: String

    private var subjects = [RateKey: PublishSubject<Rate>]()
    private var scheduler: ILatestRateScheduler?

    init(currencyCode: String, schedulerFactory: LatestRateSchedulerFactory) {
        self.currencyCode = currencyCode
        self.schedulerFactory = schedulerFactory
    }

    private func subject(key: RateKey) -> PublishSubject<Rate> {
        if let subject = subjects[key] {
            return subject
        }

        let subject = PublishSubject<Rate>()
        subjects[key] = subject
        return subject
    }

    private func updateScheduler() {
        subjects.removeAll()
        scheduler = nil

        guard !coinCodes.isEmpty else {
            return
        }

        scheduler = schedulerFactory.scheduler(coinCodes: coinCodes, currencyCode: currencyCode)
        scheduler?.schedule()
    }

}

extension LatestRateSyncManager: ILatestRateSyncManager {

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

    func latestRateObservable(key: RateKey) -> Observable<Rate> {
        subject(key: key).asObservable()
    }

}

extension LatestRateSyncManager: ILatestRateManagerDelegate {

    func didUpdate(rateInfo: Rate, key: RateKey) {
        subjects[key]?.onNext(rateInfo)
    }

}
