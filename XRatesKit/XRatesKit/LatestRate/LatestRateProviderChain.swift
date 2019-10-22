import Foundation
import RxSwift

class LatestRateProviderChain: ILatestRateProvider {
    private var concreteProviders = [ILatestRateProvider]()

    private var currentProviderIndex: Int?
    private var errors = [Error]()

    weak var delegate: ILatestRateProviderDelegate?

    func append(latestRateProvider: ILatestRateProvider) {
        concreteProviders.append(latestRateProvider)
    }

    func getLatestRates(coinCodes: [String], currencyCode: String) -> Single<[RateResponse]> {
        return latestRates(providers: concreteProviders, coinCodes: coinCodes, currencyCode: currencyCode)
    }

    private func latestRates(providers: [ILatestRateProvider], coinCodes: [String], currencyCode: String) -> Single<[RateResponse]> {
        guard let provider = providers.first else {
            return Single.error(XRatesErrors.LatestRateProvider.allProvidersReturnError)
        }
        let leftProviders = Array(providers.dropFirst())
        return provider.getLatestRates(coinCodes: coinCodes, currencyCode: currencyCode).catchError { [unowned self] (error: Error) -> Single<[RateResponse]> in
            self.latestRates(providers: leftProviders, coinCodes: coinCodes, currencyCode: currencyCode)
        }
    }

}
