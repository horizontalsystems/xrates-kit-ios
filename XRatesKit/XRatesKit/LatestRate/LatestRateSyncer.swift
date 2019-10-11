import RxSwift

class LatestRateSyncer {
    private let disposeBag = DisposeBag()
    private var disposable: Disposable?

    weak var delegate: ILatestRateSyncerDelegate?
    weak var completionDelegate: ICompletionDelegate?

    private let latestRateProvider: ILatestRateProvider
    private let storage: ILatestRateStorage
    private let dataSource: IXRatesDataSource

    init(latestRateProvider: ILatestRateProvider, storage: ILatestRateStorage, dataSource: IXRatesDataSource) {
        self.storage = storage
        self.latestRateProvider = latestRateProvider
        self.dataSource = dataSource
    }

    func subscribe(scheduler: ISyncScheduler) {
        scheduler.eventSubject.asObservable().subscribe(onNext: { [weak self] eventType in
            switch eventType {
            case .fire: self?.sync()
            case .stop: self?.cancel()
            }
        }).disposed(by: disposeBag)
    }

    private func update(rates: [Rate]) {
        rates.forEach { delegate?.didUpdate(rate: $0) }
        storage.save(rates: rates)
    }

    private func disposeRequest() {
        disposable?.dispose()
        disposable = nil
    }

}

extension LatestRateSyncer: ILatestRateSyncer {

    func sync() {
        disposeRequest()

        guard !dataSource.coinCodes.isEmpty else {
            return
        }
        disposable = latestRateProvider.getLatestRates(coinCodes: dataSource.coinCodes, currencyCode: dataSource.currencyCode)
                .subscribe(onNext: { [weak self] rates in
                    self?.update(rates: rates)
                }, onError: { _ in
                    self.completionDelegate?.onFail()
                }, onCompleted: {
                    self.completionDelegate?.onSuccess()
                }, onDisposed: {
                    self.disposeRequest()
                })

        disposable?.disposed(by: disposeBag)
    }

    func cancel() {
        disposeRequest()
    }

}
