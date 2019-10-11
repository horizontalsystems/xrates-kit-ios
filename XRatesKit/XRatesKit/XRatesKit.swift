import RxSwift

public class XRatesKit {
    private let storage: ILatestRateStorage
    private var dataSource: IXRatesDataSource
    private let dataProvider: IDataProvider
    private var latestRateSyncScheduler: ISyncScheduler
    private let subjectsHolder: ISubjectsHolder

    init(storage: ILatestRateStorage, dataSource: IXRatesDataSource, dataProvider: IDataProvider, syncScheduler: ISyncScheduler, subjectsHolder: ISubjectsHolder) {
        self.storage = storage
        self.dataSource = dataSource
        self.dataProvider = dataProvider
        self.latestRateSyncScheduler = syncScheduler
        self.subjectsHolder = subjectsHolder
    }

}

extension XRatesKit: ILatestRateSyncerDelegate {

    func didUpdate(rate: Rate) {
        let key = RateSubjectKey(coinCode: rate.coinCode, currencyCode: rate.currencyCode)
        subjectsHolder.latestRateSubjects[key]?.onNext(RateInfo(rate))
    }

}

extension XRatesKit {

    public func refresh() {
        latestRateSyncScheduler.start()
    }

    public func update(coinCodes: [String]) {
        dataSource.coinCodes = coinCodes
        subjectsHolder.clear()

        latestRateSyncScheduler.start()
    }

    public func update(currencyCode: String) {
        dataSource.currencyCode = currencyCode
        subjectsHolder.clear()

        latestRateSyncScheduler.start()
    }

    public func latestRateObservable(coinCode: String, currencyCode: String) -> Observable<RateInfo> {
        subjectsHolder.latestRateObservable(coinCode: coinCode, currencyCode: currencyCode)
    }

    public func chartStatsObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<[ChartPoint]> {
        subjectsHolder.chartStatsObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
    }

    public func latestRate(coinCode: String, currencyCode: String) -> RateInfo? {
        dataProvider.latestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

    public func historicalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        dataProvider.historicalRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
    }

    public func chartStats(coinCode: String, currencyCode: String, chartType: ChartType) -> [ChartPoint] {
        dataProvider.chartPoints(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
    }

}

extension XRatesKit {

    public static func instance(currencyCode: String, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)
        let currentDateProvider = CurrentDateProvider()

        let storage = GrdbStorage()
        let dataSource = XRatesDataSource(currencyCode: currencyCode)

        let networkManager = NetworkManager(logger: logger)
        let cryptoCompareFactory = CryptoCompareFactory(dateProvider: currentDateProvider)
        let cryptoCompareProvider = CryptoCompareProvider(networkManager: networkManager, cryptoCompareFactory: cryptoCompareFactory, baseUrl: "https://min-api.cryptocompare.com", timeoutInterval: 10)

        let syncScheduler = SyncScheduler(timeInterval: 5 * 60, retryInterval: 1 * 60)

        let syncer = LatestRateSyncer(latestRateProvider: cryptoCompareProvider, storage: storage, dataSource: dataSource)
        syncer.subscribe(scheduler: syncScheduler)
        syncer.completionDelegate = syncScheduler

        let historicalRateManager = HistoricalRateManager(storage: storage, provider: cryptoCompareProvider)

        let chartStatsSyncer = ChartStatsSyncer(storage: storage, dataSource: dataSource, provider: cryptoCompareProvider, currentDateProvider: currentDateProvider)
        syncer.subscribe(scheduler: syncScheduler)

        let subjectsHolder = SubjectsHolder()
        let dataProvider = DataProvider(storage: storage, subjectsHolder: subjectsHolder, historicalRateManager: historicalRateManager, chartStatsSyncer: chartStatsSyncer, factory: DataProviderFactory())
        let kit = XRatesKit(storage: storage, dataSource: dataSource, dataProvider: dataProvider, syncScheduler: syncScheduler, subjectsHolder: subjectsHolder)

        syncer.delegate = kit
        chartStatsSyncer.delegate = dataProvider

        return kit
    }

}
