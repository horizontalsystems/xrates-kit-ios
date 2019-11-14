platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'XRatesKit'

project 'XRatesKit/XRatesKit'
project 'Demo/Demo'

def common_pods
  pod 'RxSwift', '~> 5.0'
  pod 'RxSwiftExt', '~> 5'
  pod 'Alamofire', '~> 4.0'
  pod 'GRDB.swift', '~> 4.0'
  pod 'ObjectMapper', '~> 3.5'
end

target :XRatesKit do
  project 'XRatesKit/XRatesKit'
  common_pods
end

target :Demo do
  project 'Demo/Demo'

  pod 'SnapKit'
  common_pods
end

target :XRatesKitTests do
  project 'XRatesKit/XRatesKit'
  pod 'Cuckoo'
  pod 'Quick'
  pod 'Nimble'
end
