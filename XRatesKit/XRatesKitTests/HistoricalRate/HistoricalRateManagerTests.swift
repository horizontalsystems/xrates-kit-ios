import RxSwift
import XCTest
import Quick
import Nimble
import Cuckoo
@testable import XRatesKit

class HistoricalRateManagerTests: QuickSpec {

    override func spec() {
        let disposeBag = DisposeBag()

        let mockStorage = MockIHistoricalRateStorage()
        let mockProvider = MockIHistoricalRateProvider()

        let manager = HistoricalRateManager(storage: mockStorage, provider: mockProvider)

        afterEach {
            reset(mockStorage)
            reset(mockProvider)
        }

        let rate = LatestRate.mock(coinCode: "A", currencyCode: "B", value: 10, date: Date(), isLatest: false)
        describe("#getHistoricalRate") {
            it("gets rate from db and return rate value as single") {
                stub(mockStorage) { mock in
                    when(mock.rate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))).thenReturn(rate)
                }

                var dbRateValue: Decimal?
                manager.historicalRateSingle(coinCode: rate.coinCode, currencyCode: rate.currencyCode, timestamp: rate.timestamp)
                    .subscribe(onSuccess: { decimal in
                        dbRateValue = decimal
                    })
                    .disposed(by: disposeBag)

                verify(mockStorage).rate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))
                expect(dbRateValue).to(equal(rate.value))
            }
            it("gets rate from provider, save to db and return value as single") {
                let single = PublishSubject<LatestRate>()
                stub(mockStorage) { mock in
                    when(mock.rate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))).thenReturn(nil)
                    when(mock.save(rate: equal(to: rate))).thenDoNothing()
                }
                stub(mockProvider) {mock in
                    when(mock.getHistoricalRate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))).thenReturn(single.asSingle())
                }

                var providerRateValue: Decimal?
                manager.historicalRateSingle(coinCode: rate.coinCode, currencyCode: rate.currencyCode, timestamp: rate.timestamp)
                        .subscribe(onSuccess: { decimal in
                            providerRateValue = decimal
                        })
                        .disposed(by: disposeBag)
                single.onNext(rate)
                single.onCompleted()

                verify(mockStorage).rate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))
                verify(mockProvider).getHistoricalRate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))
                verify(mockStorage).save(rate: equal(to: rate))

                expect(providerRateValue).to(equal(rate.value))
            }
        }
    }

}