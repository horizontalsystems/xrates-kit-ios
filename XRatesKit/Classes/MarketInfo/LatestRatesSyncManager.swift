import RxSwift
import CoinKit

class LatestRatesSyncManager {
    private let schedulerFactory: LatestRatesSchedulerFactory

    private var coinTypes = [CoinType]()
    private var currencyCode: String

    private var subjects = [PairKey: PublishSubject<LatestRate>]()
    private var currencySubjects = [String: PublishSubject<[CoinType: LatestRate]>]()
    private var scheduler: ILatestRatesScheduler?

    private let queue = DispatchQueue(label: "io.horizontalsystems.x_rates_kit.market_info_sync_manager", qos: .userInitiated)

    init(currencyCode: String, schedulerFactory: LatestRatesSchedulerFactory) {
        self.currencyCode = currencyCode
        self.schedulerFactory = schedulerFactory
    }

    private func subject(key: PairKey) -> PublishSubject<LatestRate> {
        if let subject = subjects[key] {
            return subject
        }

        let subject = PublishSubject<LatestRate>()
        subjects[key] = subject
        return subject
    }

    private func currencySubject(currencyCode: String) -> PublishSubject<[CoinType: LatestRate]> {
        if let subject = currencySubjects[currencyCode] {
            return subject
        }

        let subject = PublishSubject<[CoinType: LatestRate]>()
        currencySubjects[currencyCode] = subject
        return subject
    }

    private func updateScheduler() {
        scheduler = nil

        guard !coinTypes.isEmpty else {
            return
        }

        scheduler = schedulerFactory.scheduler(coinTypes: coinTypes, currencyCode: currencyCode)
        scheduler?.schedule()
    }

}

extension LatestRatesSyncManager: ILatestRateSyncManager {

    func set(coinTypes: [CoinType]) {
        self.coinTypes = coinTypes
        updateScheduler()
    }

    func set(currencyCode: String) {
        self.currencyCode = currencyCode
        updateScheduler()
    }

    func refresh() {
        scheduler?.forceSchedule()
    }

    func latestRateObservable(key: PairKey) -> Observable<LatestRate> {
        queue.sync {
            subject(key: key).asObservable()
        }
    }

    func latestRatesObservable(currencyCode: String) -> Observable<[CoinType: LatestRate]> {
        queue.sync {
            currencySubject(currencyCode: currencyCode).asObservable()
        }
    }

}

extension LatestRatesSyncManager: ILatestRatesManagerDelegate {

    func didUpdate(latestRate: LatestRate, key: PairKey) {
        queue.async {
            self.subjects[key]?.onNext(latestRate)
        }
    }

    func didUpdate(latestRates: [CoinType: LatestRate], currencyCode: String) {
        queue.async {
            self.currencySubjects[currencyCode]?.onNext(latestRates)
        }
    }

}
