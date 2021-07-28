import RxSwift
import CoinKit

struct LatestRateKey: Hashable {
    let coinTypes: [CoinType]
    let currencyCode: String

    var ids: [String] {
        coinTypes.map {
            $0.id
        }.sorted()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(currencyCode)
        ids.forEach {
            hasher.combine($0)
        }
    }

    static func ==(lhs: LatestRateKey, rhs: LatestRateKey) -> Bool {
        lhs.ids == rhs.ids && lhs.currencyCode == rhs.currencyCode
    }

}

class LatestRatesSyncManager {
    private let queue = DispatchQueue(label: "io.horizontalsystems.x_rates_kit.market_info_sync_manager", qos: .userInitiated)

    private let schedulerFactory: LatestRatesSchedulerFactory
    private var schedulers = [String: IScheduler]()
    private var subjects = [LatestRateKey: PublishSubject<[CoinType: LatestRate]>]()

    init(schedulerFactory: LatestRatesSchedulerFactory) {
        self.schedulerFactory = schedulerFactory
    }

    private func cleanUp(key: LatestRateKey) {
        if let subject = subjects[key], subject.hasObservers {
            return
        }
        subjects[key] = nil

        if subjects.filter({ (subjectKey, _) in subjectKey.currencyCode == key.currencyCode }).isEmpty {
            schedulers[key.currencyCode] = nil
        }
    }

    private func onDisposed(key: LatestRateKey) {
        queue.async {
            self.cleanUp(key: key)
        }
    }

    private func observingCoinTypes(currencyCode: String) -> Set<CoinType> {
        var coinTypes = Set<CoinType>()
        subjects.forEach { existKey, _ in
            if existKey.currencyCode == currencyCode {
                coinTypes.formUnion(Set(existKey.coinTypes))
            }
        }
        return coinTypes
    }

    private var observingCurrencies: Set<String> {
        var currencyCodes = Set<String>()
        subjects.forEach { existKey, _ in
            currencyCodes.insert(existKey.currencyCode)
        }
        return currencyCodes
    }

    private func needForceUpdate(key: LatestRateKey) -> Bool {
        //get set of all listening coins
        //found tokens which needed to update
        //make new key for force update

        let newCoinTypes = Set(key.coinTypes).subtracting(observingCoinTypes(currencyCode: key.currencyCode))
        return !newCoinTypes.isEmpty
    }

    private func subject(key: LatestRateKey) -> Observable<[CoinType: LatestRate]> {
        let subject: PublishSubject<[CoinType: LatestRate]>
        var forceUpdate: Bool = false

        if let candidate = subjects[key] {
            subject = candidate
        } else {                                        // create new subject
            forceUpdate = needForceUpdate(key: key)     // if subject has non-subscribed tokens we need force schedule

            subject = PublishSubject<[CoinType: LatestRate]>()
            subjects[key] = subject
        }

        if schedulers[key.currencyCode] == nil {        // create scheduler if not exist
            let scheduler = schedulerFactory.scheduler(currencyCode: key.currencyCode, coinTypeDataSource: self)

            schedulers[key.currencyCode] = scheduler
        }

        if forceUpdate {                                // make request for scheduler immediately
            schedulers[key.currencyCode]?.forceSchedule()
        }

        return subject
                .do(onDispose: { [weak self] in
                    self?.onDisposed(key: key)
                })
    }

}

extension LatestRatesSyncManager: ILatestRatesCoinTypeDataSource {

    func coinTypes(currencyCode: String) -> [CoinType] {
        Array(observingCoinTypes(currencyCode: currencyCode))
    }

}

extension LatestRatesSyncManager: ILatestRateSyncManager {

    func latestRatesObservable(coinTypes: [CoinType], currencyCode: String) -> Observable<[CoinType: LatestRate]> {
        let key = LatestRateKey(coinTypes: coinTypes, currencyCode: currencyCode)

        return queue.sync {
            subject(key: key).asObservable()
        }
    }

    func refresh(currencyCode: String) {
        queue.async {
            self.schedulers[currencyCode]?.forceSchedule()
        }
    }

    func latestRateObservable(key: PairKey) -> Observable<LatestRate> {
        queue.sync {
            let latestRateKey = LatestRateKey(coinTypes: [key.coinType], currencyCode: key.currencyCode)

            return self.subject(key: latestRateKey)
                    .flatMap { dictionary -> Observable<LatestRate> in
                        if let latestRate = dictionary[key.coinType] {
                            return Observable.just(latestRate)
                        }
                        return Observable.never()
                    }
        }
    }

}

extension LatestRatesSyncManager: ILatestRatesManagerDelegate {

    var coinTypes: [String: [CoinType]] {       // collect all coinTypes from subscribers
        queue.sync {
            var result = [String: [CoinType]]()

            observingCurrencies.forEach { currencyCode in
                result[currencyCode] = Array(observingCoinTypes(currencyCode: currencyCode))
            }

            return result
        }
    }

    func didUpdate(latestRates: [CoinType: LatestRate], currencyCode: String) {
        queue.async {
            self.subjects.forEach { key, subject in
                // send new rates for all subject which has at least one coinType in key
                if key.currencyCode == currencyCode {
                    let rates = latestRates.filter { rateKey, _ in
                        key.coinTypes.contains(rateKey)
                    }

                    if !rates.isEmpty {
                        subject.onNext(rates)
                    }
                }
            }
        }
    }

}
