import Foundation
import Alamofire
import HsToolKit
import RxSwift

class ProviderNetworkManager {
    private let networkManager: NetworkManager
    private let requestInterval: TimeInterval
    private let logger: Logger

    private var lastRequestTime = Date().timeIntervalSince1970
    private let scheduler = SerialDispatchQueueScheduler(qos: .background)

    var session: Session {
        networkManager.session
    }

    init(requestInterval: TimeInterval, logger: Logger) {
        networkManager = NetworkManager(logger: logger)

        self.requestInterval = requestInterval
        self.logger = logger
    }

    func single<Mapper: IApiMapper>(request: DataRequest, mapper: Mapper) -> Single<Mapper.T> {
        logger.info("Request: \(request.description)")
        let currentTime = Date().timeIntervalSince1970
        let timePassedFromLastRequest =  currentTime - lastRequestTime
        let timeToWait = requestInterval - timePassedFromLastRequest

        let single = networkManager.single(request: request, mapper: mapper)
        lastRequestTime = currentTime

        guard timeToWait > 0 else {
            return single
        }

        logger.info("Delay for \(timeToWait) milliseconds")

        return Single<Int>
                .timer(.seconds(1), scheduler: scheduler)
                .flatMap { _ in single }
    }

}
