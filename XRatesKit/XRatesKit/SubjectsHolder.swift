import RxSwift

class SubjectsHolder {

    var latestRateSubjects = [RateSubjectKey: PublishSubject<RateInfo>]()
    var chartStatsSubjects = [ChartStatsSubjectKey: PublishSubject<[ChartPoint]>]()

}

extension SubjectsHolder: ISubjectsHolder {

    func clear() {
        latestRateSubjects.removeAll()
        chartStatsSubjects.removeAll()
    }

    func latestRateObservable(coinCode: String, currencyCode: String) -> Observable<RateInfo> {
        let key = RateSubjectKey(coinCode: coinCode, currencyCode: currencyCode)

        let subject: PublishSubject<RateInfo>

        if let latestRateSubject = latestRateSubjects[key] {
            subject = latestRateSubject
        } else {
            subject = PublishSubject<RateInfo>()
            latestRateSubjects[key] = subject
        }

        return subject.asObservable()
    }

    func chartStatsObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<[ChartPoint]> {
        let key = ChartStatsSubjectKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)

        let subject: PublishSubject<[ChartPoint]>
        if let chartStatsSubject = chartStatsSubjects[key] {
            subject = chartStatsSubject
        } else {
            subject = PublishSubject<[ChartPoint]>()
            chartStatsSubjects[key] = subject
        }

        return subject.asObservable()
    }

    var activeChartStatsKeys: [ChartStatsSubjectKey] {
        var activeKeys = [ChartStatsSubjectKey]()
        chartStatsSubjects.forEach { key, subject in
            if subject.hasObservers {
                activeKeys.append(key)
            }
        }
        return activeKeys
    }

}
