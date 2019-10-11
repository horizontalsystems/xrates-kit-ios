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

protocol IChartStatsStorage {
    func marketStats(coinCodes: [String], currencyCode: String) -> [MarketStats]
    func save(marketStats: MarketStats)
    func chartStatList(coinCode: String, currencyCode: String, chartType: ChartType) -> [ChartStats]
    func save(chartStatList: [ChartStats])
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

protocol IChartStatsSyncer {
    func syncChartStats(coinCode: String, currencyCode: String, chartType: ChartType)
}

protocol IChartStatsManagerDelegate: class {
    func didUpdate(chartStatList: [ChartStats], coinCode: String, currencyCode: String, chartType: ChartType)
}

protocol IChartStatsProvider {
    func getChartStats(coinCode: String, currencyCode: String, chartType: ChartType) -> Single<[ChartStats]>
    func getMarketStats(coinCodes: [String], currencyCode: String) -> Single<[MarketStats]>
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
    var eventSubject: PublishSubject<SyncEventState> { get }

    func start()
    func stop()
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
    func marketStats(coinCode: String, currencyCode: String, response: CryptoCompareMarketInfoResponse) -> MarketStats?
    func historicalRate(coinCode: String, currencyCode: String, date: Date, value: Decimal) -> Rate
}

protocol IDataProviderFactory {
    func rateInfo(_ rate: Rate) -> RateInfo
    func chartPoint(_ chartStats: ChartStats) -> ChartPoint
    func chartPoint(timestamp: TimeInterval, value: Decimal) -> ChartPoint
}

protocol ISubjectsHolder {
    var activeChartStatsKeys: [ChartStatsSubjectKey] { get }
    var latestRateSubjects: [RateSubjectKey: PublishSubject<RateInfo>] { get }
    var chartStatsSubjects: [ChartStatsSubjectKey: PublishSubject<[ChartPoint]>] { get }

    func clear()
    func latestRateObservable(coinCode: String, currencyCode: String) -> Observable<RateInfo>
    func chartStatsObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<[ChartPoint]>
}

protocol IDataProvider {
    func latestRate(coinCode: String, currencyCode: String) -> RateInfo?
    func historicalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal>
    func chartPoints(coinCode: String, currencyCode: String, chartType: ChartType) -> [ChartPoint]
}
