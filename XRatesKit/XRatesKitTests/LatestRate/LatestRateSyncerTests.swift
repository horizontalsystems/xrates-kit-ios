import RxSwift
import XCTest
import Quick
import Nimble
import Cuckoo
@testable import XRatesKit

class LatestRateSyncerTests: QuickSpec {

    override func spec() {

        let mockDelegate = MockILatestRateSyncerDelegate()
        let mockCompletionDelegate = MockICompletionDelegate()
        let mockLatestRateProvider = MockILatestRateProvider()
        let mockStorage = MockILatestRateStorage()
        let mockDataSource = MockIXRatesDataSource()

        let syncer = LatestRateSyncer(latestRateProvider: mockLatestRateProvider, storage: mockStorage, dataSource: mockDataSource)
        syncer.delegate = mockDelegate
        syncer.completionDelegate = mockCompletionDelegate

        afterEach {
            reset(mockDelegate)
            reset(mockCompletionDelegate)
            reset(mockLatestRateProvider)
            reset(mockStorage)
            reset(mockDataSource)
        }

        let coinCodes = ["A", "B"]
        let currencyCode = "C"
        describe("#sync") {
            beforeEach {
                stub(mockCompletionDelegate) { mock in
                    when(mock.onSuccess()).thenDoNothing()
                }
                stub(mockDataSource) { mock in
                    when(mock.coinCodes.get).thenReturn(coinCodes)
                    when(mock.currencyCode.get).thenReturn(currencyCode)
                }
            }
            it("ignores double call sync when first request not finished yet") {
                let publisher = PublishSubject<[Rate]>()
                stub(mockLatestRateProvider) { mock in
                    when(mock.getLatestRates(coinCodes: coinCodes, currencyCode: currencyCode)).thenReturn(publisher.asObservable())
                }

                syncer.sync()
                syncer.sync()

                verify(mockDataSource, times(1)).coinCodes.get()
                verify(mockDataSource, times(1)).currencyCode.get()
                verify(mockLatestRateProvider, times(1)).getLatestRates(coinCodes: coinCodes, currencyCode: currencyCode)

                verify(mockCompletionDelegate, never()).onSuccess()
                verify(mockCompletionDelegate, never()).onFail()

                publisher.onCompleted()
            }
            it("throws error an return onFail, dispose observable to ability next calls") {
                let publisher = PublishSubject<[Rate]>()
                stub(mockLatestRateProvider) { mock in
                    when(mock.getLatestRates(coinCodes: coinCodes, currencyCode: currencyCode)).thenReturn(publisher.asObservable())
                }
                stub(mockCompletionDelegate) { mock in
                    when(mock.onFail()).thenDoNothing()
                }

                syncer.sync()
                publisher.onError(TestError.defaultError)
                publisher.onCompleted()

                verify(mockCompletionDelegate, times(1)).onFail()

                syncer.sync()

                verify(mockDataSource, times(2)).coinCodes.get()
                verify(mockDataSource, times(2)).currencyCode.get()

                publisher.onCompleted()
            }
            it("adds rates to storage, call delegate didUpdate for each rate, call onSuccess on completed") {
                let publisher = PublishSubject<[Rate]>()
                let rates = coinCodes.map { Rate.mock(coinCode: $0) }
                stub(mockLatestRateProvider) { mock in
                    when(mock.getLatestRates(coinCodes: coinCodes, currencyCode: currencyCode)).thenReturn(publisher.asObservable())
                }
                stub(mockDelegate) { mock in
                    when(mock.didUpdate(rate: equal(to: rates[0]))).thenDoNothing()
                    when(mock.didUpdate(rate: equal(to: rates[1]))).thenDoNothing()
                }
                stub(mockCompletionDelegate) { mock in
                    when(mock.onSuccess()).thenDoNothing()
                }
                stub(mockStorage) { mock in
                    when(mock.save(rates: equal(to: rates))).thenDoNothing()
                }

                syncer.sync()
                publisher.onNext(rates)
                publisher.onCompleted()

                verify(mockDelegate).didUpdate(rate: equal(to: rates[0]))
                verify(mockDelegate).didUpdate(rate: equal(to: rates[1]))
                verify(mockStorage).save(rates: equal(to: rates))

                verify(mockCompletionDelegate).onSuccess()
            }
        }
    }

}