import RxSwift

class NewsProvider {
}

extension NewsProvider: INewsProvider {

    func newsSingle(latestTimestamp: TimeInterval?) -> Single<Int> {
        Single.just(0)
    }

}
