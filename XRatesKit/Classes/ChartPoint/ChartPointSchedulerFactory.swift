import Foundation
import HsToolKit

class ChartPointSchedulerFactory {
    private let manager: IChartInfoManager
    private let provider: IChartPointProvider
    private let reachabilityManager: IReachabilityManager
    private let retryInterval: TimeInterval
    private var logger: Logger?

    init(manager: IChartInfoManager, provider: IChartPointProvider, reachabilityManager: IReachabilityManager, retryInterval: TimeInterval, logger: Logger? = nil) {
        self.manager = manager
        self.provider = provider
        self.reachabilityManager = reachabilityManager
        self.retryInterval = retryInterval
        self.logger = logger
    }

    func scheduler(key: ChartInfoKey) -> IScheduler {
        let schedulerProvider = ChartPointSchedulerProvider(key: key, manager: manager, provider: provider, retryInterval: retryInterval)
        return Scheduler(provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

}
