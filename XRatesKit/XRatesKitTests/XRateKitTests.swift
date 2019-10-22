import RxSwift
import XCTest
import Quick
import Nimble
import Cuckoo
@testable import XRatesKit

class XRatesKitTests: QuickSpec {

    override func spec() {
        let disposeBag = DisposeBag()

        let mockStorage = MockILatestRateStorage()
        let mockDataSource = MockIXRatesDataSource()
        let mockSyncScheduler = MockISyncScheduler()
        let mockHistoricalRateManager = MockIHistoricalRateManager()
        let mockChartStatsManager = MockIChartStatsManager()

        let kit = XRatesKit(storage: mockStorage, dataSource: mockDataSource, latestRateScheduler: mockSyncScheduler, historicalRateManager: mockHistoricalRateManager, chartStatsManager: mockChartStatsManager)

        beforeEach {
            stub(mockSyncScheduler) { mock in
                when(mock.start()).thenDoNothing()
            }
        }

        afterEach {
            reset(mockStorage)
            reset(mockDataSource)
            reset(mockSyncScheduler)
            reset(mockHistoricalRateManager)
        }

        let coinCodes = ["A", "B"]
        let currencyCode = "C"
        let latestRate = LatestRate.mock(coinCode: coinCodes[0], currencyCode: currencyCode, isLatest: true)

        describe("#start") {
            it("set coins and calls scheduler's start") {
                stub(mockDataSource) { mock in
                    when(mock.coinCodes.set(any())).thenDoNothing()
                    when(mock.currencyCode.set(any())).thenDoNothing()
                }
                kit.start(coinsCodes: coinCodes, currencyCode: currencyCode)

                verify(mockDataSource).coinCodes.set(equal(to: coinCodes))
                verify(mockDataSource).currencyCode.set(equal(to: currencyCode))
                verify(mockSyncScheduler).start()
            }
        }
        describe("#refresh") {
            it("calls scheduler's start") {
                kit.refresh()

                verify(mockSyncScheduler).start()
            }
        }
        describe("#latestRate") {
            beforeEach {
                stub(mockStorage) { mock in
                    when(mock.latestRate(coinCode: equal(to: coinCodes[0]), currencyCode: equal(to: currencyCode))).thenReturn(latestRate)
                }
            }
            it("gets latest rate for coin from data storage") {
                let latestRate = kit.latestRate(coinCode: coinCodes[0], currency: currencyCode)

                verify(mockStorage).latestRate(coinCode: coinCodes[0], currencyCode: currencyCode)
                expect(latestRate).to(equal(latestRate))
            }
        }
        describe("#historicalRate") {
            it("gets historical rate for coin from historical manager") {
                let rate = LatestRate.mock(coinCode: coinCodes[0], currencyCode: currencyCode, date: Date(), isLatest: false)
                let single = PublishSubject<Decimal>().asSingle()
                stub(mockHistoricalRateManager) { mock in
                    when(mock.getHistoricalRate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))).thenReturn(single)
                }

                _ = kit.historicalRate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, timestamp: rate.timestamp)

                verify(mockHistoricalRateManager).getHistoricalRate(coinCode: rate.coinCode, currencyCode: rate.currencyCode, date: equal(to: rate.timestamp))
            }
        }
        describe("#update coin codes") {
            it("changes coinCodes in source, sync data provider") {
                let newCoinCodes = ["A", "B", "C"]
                stub(mockDataSource) { mock in
                    when(mock.coinCodes.set(equal(to: newCoinCodes))).thenDoNothing()
                }
                kit.set(coinCodes: newCoinCodes)

                verify(mockDataSource).coinCodes.set(equal(to: newCoinCodes))
                verify(mockSyncScheduler).start()
            }
        }
        describe("#update currency code") {
            it("changes currencyCode in source, sync data provider") {
                let newCurrencyCode = "New"
                stub(mockDataSource) { mock in
                    when(mock.currencyCode.set(equal(to: newCurrencyCode))).thenDoNothing()
                }
                kit.set(currencyCode: newCurrencyCode)

                verify(mockDataSource).currencyCode.set(equal(to: newCurrencyCode))
                verify(mockSyncScheduler).start()
            }
        }
        describe("#didSync") {
            beforeEach {
                stub(mockStorage) { mock in
                    when(mock.latestRate(coinCode: equal(to: coinCodes[0]), currencyCode: equal(to: currencyCode))).thenReturn(latestRate)
                }
            }
            it("check emmit rate to publisher") {
                var calledRate: Rate?
                kit.rateSubject
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { latestRate in
                            calledRate = latestRate
                        })
                        .disposed(by: disposeBag)

                kit.didUpdate(rate: latestRate)
                self.waitForMainQueue()
                expect(calledRate).to(equal(Rate(latestRate)))
            }
        }
    }

}