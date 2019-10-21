import RxSwift
import Alamofire

class ReachabilityManager {
    private let manager: NetworkReachabilityManager?

    private(set) var isReachable: Bool
    private let reachabilitySubject = PublishSubject<Bool>()

    init() {
        manager = NetworkReachabilityManager(host: "min-api.cryptocompare.com")

        isReachable = manager?.isReachable ?? false

        manager?.listener = { [weak self] _ in
            self?.onUpdateStatus()
        }

        manager?.startListening()
    }

    private func onUpdateStatus() {
        let newReachable = manager?.isReachable ?? false

        if isReachable != newReachable {
            isReachable = newReachable
            reachabilitySubject.onNext(isReachable)
        }
    }

}

extension ReachabilityManager: IReachabilityManager {

    var reachabilityObservable: Observable<Bool> {
        reachabilitySubject.asObservable()
    }

}
