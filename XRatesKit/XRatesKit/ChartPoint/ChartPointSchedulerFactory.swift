import Foundation

class ChartPointSchedulerFactory {
    private let manager: IChartPointManager
    private let provider: IChartPointProvider
    private let reachabilityManager: IReachabilityManager
    private let retryInterval: TimeInterval
    private var logger: Logger?

    init(manager: IChartPointManager, provider: IChartPointProvider, reachabilityManager: IReachabilityManager, retryInterval: TimeInterval, logger: Logger? = nil) {
        self.manager = manager
        self.provider = provider
        self.reachabilityManager = reachabilityManager
        self.retryInterval = retryInterval
        self.logger = logger
    }

    func scheduler(key: ChartPointKey) -> ChartPointScheduler {
        let schedulerProvider: IChartPointSchedulerProvider = ChartPointSchedulerProvider(key: key, manager: manager, provider: provider, retryInterval: retryInterval)
        return ChartPointScheduler(provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

}
