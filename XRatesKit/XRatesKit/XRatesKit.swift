import RxSwift

public class XRatesKit {
    private let disposeBag = DisposeBag()

    private let storage: ILatestRateStorage
    private var dataSource: IXRatesDataSource
    private var latestRateSyncScheduler: ISyncScheduler
    private let historicalRateManager: IHistoricalRateManager

    public let rateSubject = PublishSubject<RateInfo>()

    init(storage: ILatestRateStorage, dataSource: IXRatesDataSource, syncScheduler: ISyncScheduler, historicalRateManager: IHistoricalRateManager) {
        self.storage = storage
        self.dataSource = dataSource
        self.latestRateSyncScheduler = syncScheduler
        self.historicalRateManager = historicalRateManager
    }

}

extension XRatesKit: ILatestRateSyncerDelegate {

    func didUpdate(rate: Rate) {
        rateSubject.onNext(RateInfo(rate))
    }

}

extension XRatesKit {

    public func start(coinsCodes: [String], currencyCode: String) {
        dataSource.coinCodes = coinsCodes
        dataSource.currencyCode = currencyCode

        latestRateSyncScheduler.start()
    }

    public func refresh() {
        latestRateSyncScheduler.start()
    }

    public func stop() {
        latestRateSyncScheduler.stop()
    }

    public func update(coinCodes: [String]) {
        dataSource.coinCodes = coinCodes

        latestRateSyncScheduler.start()
    }

    public func update(currencyCode: String) {
        dataSource.currencyCode = currencyCode

        latestRateSyncScheduler.start()
    }

    public func latestRate(coinCode: String, currency: String) -> RateInfo? {
        storage.latestRate(coinCode: coinCode, currencyCode: currency).map { RateInfo($0) }
    }

    public func historicalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        historicalRateManager.getHistoricalRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
    }

}

extension XRatesKit {

    public static func instance(minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let storage = GrdbStorage()
        let dataSource = XRatesDataSource()

        let networkManager = NetworkManager(logger: logger)
        let cryptoCompareFactory = CryptoCompareFactory(dateProvider: CurrentDateProvider())
        let cryptoCompareProvider = CryptoCompareProvider(networkManager: networkManager, cryptoCompareFactory: cryptoCompareFactory, baseUrl: "https://min-api.cryptocompare.com", timeoutInterval: 10)

        let syncer = LatestRateSyncer(latestRateProvider: cryptoCompareProvider, storage: storage, dataSource: dataSource)

        let syncScheduler = SyncScheduler(timeInterval: 10 * 60, retryInterval: 1 * 60)
        syncScheduler.delegate = syncer
        syncer.completionDelegate = syncScheduler

        let historicalRateManager = HistoricalRateManager(storage: storage, provider: cryptoCompareProvider)
        let kit = XRatesKit(storage: storage, dataSource: dataSource, syncScheduler: syncScheduler, historicalRateManager: historicalRateManager)

        syncer.delegate = kit

        return kit
    }

}
