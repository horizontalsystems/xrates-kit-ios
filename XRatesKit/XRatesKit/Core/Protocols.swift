import RxSwift
import Foundation

protocol ILatestRateStorage {
    func latestRate(coinCode: String, currencyCode: String) -> Rate?
    func save(rates: [Rate])
}

protocol IHistoricalRateStorage {
    func rate(coinCode: String, currencyCode: String, date: Date) -> Rate?
    func save(rate: Rate)
}

protocol ILatestRateSyncer {
    var delegate: ILatestRateSyncerDelegate? { get set }
    func sync()
    func cancel()
}

protocol ILatestRateSyncerDelegate: AnyObject {
    func didUpdate(rate: Rate)
}

protocol ILatestRateProvider: class {
    func getLatestRates(coinCodes: [String], currencyCode: String) -> Observable<[Rate]>
}

protocol IHistoricalRateManager {
    func getHistoricalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal>
}

protocol IHistoricalRateProvider {
    func getHistoricalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Rate>
}

protocol ILatestRateProviderDelegate: class {
    func didReceive(rate: Rate)
    func didSuccess()
    func didFail(error: Error)
}

protocol IXRatesDataSource {
    var coinCodes: [String] { get set }
    var currencyCode: String { get set }
}

protocol ISyncScheduler {
    var delegate: ISyncSchedulerDelegate? { get set }

    func start()
    func stop()
}

protocol ISyncSchedulerDelegate: class {
    func onFire()
    func onStop()
}

protocol ICompletionDelegate: class {
    func onSuccess()
    func onFail()
}

protocol ICurrentDateProvider {
    var currentDate: Date { get }
}

protocol ICryptoCompareFactory {
    func latestRate(coinCode: String, currencyCode: String, response: CryptoCompareLatestRateResponse) -> Rate?
    func historicalRate(coinCode: String, currencyCode: String, date: Date, value: Decimal) -> Rate
}
