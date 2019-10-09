import RxSwift

class SyncScheduler: ISyncScheduler {
    private var disposeBag: DisposeBag?
    var delegate: ISyncSchedulerDelegate?

    private let schedulerType: SchedulerType
    private let timeInterval: Int
    private let retryInterval: Int

    init(timeInterval: Int, retryInterval: Int, schedulerType: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background), delegate: ISyncSchedulerDelegate? = nil) {
        self.timeInterval = timeInterval
        self.retryInterval = retryInterval
        self.schedulerType = schedulerType
        self.delegate = delegate
    }

    private func start(delay time: Int) {
        let disposeBag = DisposeBag()

        Observable<Int>.timer(.seconds(time), scheduler: schedulerType)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.onFire()
                })
                .disposed(by: disposeBag)

        self.disposeBag = disposeBag
    }

    func start() {
        start(delay: 0)
    }

    func stop() {
        self.disposeBag = DisposeBag()
        self.delegate?.onStop()
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
