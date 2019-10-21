import RxSwift

class ChartPointSyncManager {
    private let schedulerFactory: ChartPointSchedulerFactory

    private var subjects = [ChartPointKey: PublishSubject<[ChartPoint]>]()
    private var schedulers = [ChartPointKey: ChartPointScheduler]()

    init(schedulerFactory: ChartPointSchedulerFactory) {
        self.schedulerFactory = schedulerFactory
    }

    private func subject(key: ChartPointKey) -> PublishSubject<[ChartPoint]> {
        if let subject = subjects[key] {
            return subject
        }

        let subject = PublishSubject<[ChartPoint]>()
        subjects[key] = subject
        return subject
    }

    private func scheduler(key: ChartPointKey) -> ChartPointScheduler {
        if let scheduler = schedulers[key] {
            return scheduler
        }

        let scheduler = schedulerFactory.scheduler(key: key)
        schedulers[key] = scheduler
        return scheduler
    }

    private func cleanUp(key: ChartPointKey) {
        if let subject = subjects[key], subject.hasObservers {
            return
        }

        subjects[key] = nil
        schedulers[key] = nil
    }

}

extension ChartPointSyncManager: IChartPointSyncManager {

    func chartPointsObservable(key: ChartPointKey) -> Observable<[ChartPoint]> {
        subject(key: key)
                .do(onSubscribed: { [weak self] in
                    self?.scheduler(key: key).schedule()
                }, onDispose: { [weak self] in
                    self?.cleanUp(key: key)
                })
    }

}

extension ChartPointSyncManager: IChartPointManagerDelegate {

    func didUpdate(chartPoints: [ChartPoint], key: ChartPointKey) {
        subjects[key]?.onNext(chartPoints)
    }

}
