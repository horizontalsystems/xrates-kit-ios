import RxSwift

class MarketInfoSyncManager {
    private let schedulerFactory: MarketInfoSchedulerFactory

    private var coinCodes = [String]()
    private var currencyCode: String

    private var subjects = ThreadSafeDictionary<PairKey, PublishSubject<MarketInfo>>()
    private var currencySubjects = ThreadSafeDictionary<String, PublishSubject<[String: MarketInfo]>>()
    private var scheduler: IMarketInfoScheduler?

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
        subjects.removeAll()
        currencySubjects.removeAll()
        scheduler = nil

        guard !coinCodes.isEmpty else {
            return
        }

        scheduler = schedulerFactory.scheduler(coinCodes: coinCodes, currencyCode: currencyCode)
        scheduler?.schedule()
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
        subject(key: key).asObservable()
    }

    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]> {
        currencySubject(currencyCode: currencyCode).asObservable()
    }

}

extension MarketInfoSyncManager: IMarketInfoManagerDelegate {

    func didUpdate(marketInfo: MarketInfo, key: PairKey) {
        subjects[key]?.onNext(marketInfo)
    }

    func didUpdate(marketInfos: [String: MarketInfo], currencyCode: String) {
        currencySubjects[currencyCode]?.onNext(marketInfos)
    }

}
