import RxSwift
import CoinKit

class MarketInfoSyncManager {
    private let schedulerFactory: MarketInfoSchedulerFactory

    private var coinTypes = [CoinType]()
    private var currencyCode: String

    private var subjects = [PairKey: PublishSubject<MarketInfo>]()
    private var currencySubjects = [String: PublishSubject<[CoinType: MarketInfo]>]()
    private var scheduler: IMarketInfoScheduler?

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

    private func currencySubject(currencyCode: String) -> PublishSubject<[CoinType: MarketInfo]> {
        if let subject = currencySubjects[currencyCode] {
            return subject
        }

        let subject = PublishSubject<[CoinType: MarketInfo]>()
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

extension MarketInfoSyncManager: IMarketInfoSyncManager {

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

    func marketInfoObservable(key: PairKey) -> Observable<MarketInfo> {
        queue.sync {
            subject(key: key).asObservable()
        }
    }

    func marketInfosObservable(currencyCode: String) -> Observable<[CoinType: MarketInfo]> {
        queue.sync {
            currencySubject(currencyCode: currencyCode).asObservable()
        }
    }

}

extension MarketInfoSyncManager: IMarketInfoManagerDelegate {

    func didUpdate(marketInfo: MarketInfo, key: PairKey) {
        queue.async {
            self.subjects[key]?.onNext(marketInfo)
        }
    }

    func didUpdate(marketInfos: [CoinType: MarketInfo], currencyCode: String) {
        queue.async {
            self.currencySubjects[currencyCode]?.onNext(marketInfos)
        }
    }

}
