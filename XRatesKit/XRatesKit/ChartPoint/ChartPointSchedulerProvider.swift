import RxSwift

class ChartPointSchedulerProvider {
    private let key: ChartInfoKey
    private let manager: IChartInfoManager
    private let provider: IChartPointProvider

    let retryInterval: TimeInterval

    init(key: ChartInfoKey, manager: IChartInfoManager, provider: IChartPointProvider, retryInterval: TimeInterval) {
        self.key = key
        self.manager = manager
        self.provider = provider
        self.retryInterval = retryInterval
    }

    private func handleUpdated(chartPoints: [ChartPoint]) {
        manager.handleUpdated(chartPoints: chartPoints, key: key)
    }

}

extension ChartPointSchedulerProvider: IChartPointSchedulerProvider {

    var logKey: String {
        "\(key)"
    }

    var lastSyncTimestamp: TimeInterval? {
        manager.lastSyncTimestamp(key: key)
    }

    var expirationInterval: TimeInterval {
        key.chartType.expirationInterval
    }

    var syncSingle: Single<Void> {
        provider.chartPointsSingle(key: key)
                .do(onSuccess: { [weak self] chartPoints in
                    self?.handleUpdated(chartPoints: chartPoints)
                })
                .map { _ in () }
    }

}
