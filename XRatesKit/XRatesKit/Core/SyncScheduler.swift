import RxSwift

enum SyncEventState {
    case fire
    case stop
}

class SyncScheduler: ISyncScheduler {
    private var disposeBag: DisposeBag?
    let eventSubject = PublishSubject<SyncEventState>()

    private let schedulerType: SchedulerType
    private let timeInterval: Int
    private let retryInterval: Int

    init(timeInterval: Int, retryInterval: Int, schedulerType: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.timeInterval = timeInterval
        self.retryInterval = retryInterval
        self.schedulerType = schedulerType
    }

    private func start(delay time: Int) {
        let disposeBag = DisposeBag()

        Observable<Int>.timer(.seconds(time), scheduler: schedulerType)
                .subscribe(onNext: { [weak self] _ in
                    self?.eventSubject.onNext(.fire)
                })
                .disposed(by: disposeBag)

        self.disposeBag = disposeBag
    }

    func start() {
        start(delay: 0)
    }

    func stop() {
        self.disposeBag = DisposeBag()
        self.eventSubject.onNext(.stop)
    }

}

extension SyncScheduler: ICompletionDelegate {

    func onSuccess() {
        start(delay: timeInterval)
    }

    func onFail() {
        start(delay: retryInterval)
    }

}
