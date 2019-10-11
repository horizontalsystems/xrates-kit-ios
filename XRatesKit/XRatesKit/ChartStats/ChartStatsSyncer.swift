import RxSwift

class ChartStatsSyncer {
    private static let refreshInterval: TimeInterval = 10 * 60
    private var disposeBag = DisposeBag()

    private let storage: IChartStatsStorage
    private let dataSource: IXRatesDataSource
    private let provider: IChartStatsProvider
    private let currentDateProvider: ICurrentDateProvider

    weak var delegate: IChartStatsManagerDelegate?

    init(storage: IChartStatsStorage & ILatestRateStorage, dataSource: IXRatesDataSource, provider: IChartStatsProvider, currentDateProvider: ICurrentDateProvider) {
        self.storage = storage
        self.dataSource = dataSource
        self.provider = provider
        self.currentDateProvider = currentDateProvider
    }

    func subscribe(scheduler: ISyncScheduler) {
        scheduler.eventSubject.asObservable().subscribe(onNext: { [weak self] eventType in
            switch eventType {
            case .fire: self?.sync()
            case .stop: self?.cancel()
            }
        }).disposed(by: disposeBag)
    }

    private func update(coinCode: String, currencyCode: String, chartType: ChartType, chartStatsList: [ChartStats]) {
        delegate?.didUpdate(chartStatList: chartStatsList, coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
        storage.save(chartStatList: chartStatsList)
    }

    private func sync() {
        //get all activeChartStatsKeys. Filter by expired chartStats from storage. sync data
    }

    private func cancel() {
        //cancel all sync disposables
    }

    private func disposeRequest() {
        disposeBag = DisposeBag()
    }

}

extension ChartStatsSyncer: IChartStatsSyncer {

    func syncChartStats(coinCode: String, currencyCode: String, chartType: ChartType) {
        provider.getChartStats(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
                .subscribe(onSuccess: { [weak self] chartStats in
                    self?.update(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType, chartStatsList: chartStats)
                }, onError: { error in
                    //do something?
                })
                .disposed(by: disposeBag)
    }
}
