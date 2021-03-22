import Foundation
import Alamofire
import HsToolKit
import RxSwift

class ProviderNetworkManager {
    private let networkManager: NetworkManager
    private let scheduler: DelayScheduler
    private let logger: Logger

    var session: Session {
        networkManager.session
    }

    init(requestInterval: TimeInterval, logger: Logger) {
        networkManager = NetworkManager(logger: logger)
        scheduler = DelayScheduler(delay: requestInterval, queue: .global(qos: .utility))
        self.logger = logger
    }

    func single<Mapper: IApiMapper>(request: DataRequest, mapper: Mapper) -> Single<Mapper.T> {
        networkManager.single(request: request, mapper: mapper)
                .subscribeOn(scheduler)
    }

}

class DelayScheduler: ImmediateSchedulerType {
    private var lastDispatch: DispatchTime = .now()
    private let queue: DispatchQueue
    private let dispatchDelay: TimeInterval

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.queue = queue
        dispatchDelay = delay
    }

    func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        let cancel = SingleAssignmentDisposable()
        lastDispatch = max(lastDispatch + dispatchDelay, .now())
        queue.asyncAfter(deadline: lastDispatch) {
            guard cancel.isDisposed == false else { return }
            cancel.setDisposable(action(state))
        }
        return cancel
    }

}
