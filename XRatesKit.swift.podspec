Pod::Spec.new do |spec|
  spec.name = 'XRatesKit.swift'
  spec.module_name = 'XRatesKit'
  spec.version = '0.3'
  spec.summary = 'Kit provide latest rates for coins, chart data and historical data for different coins and currencies'
  spec.description = <<-DESC
                       Kit provide latest rates for coins, chart data and historical data for different coins and currencies uses different providers.
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/x-rates-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/x-rates-kit-ios.git', tag: "#{spec.version}" }
  spec.source_files = 'XRatesKit/XRatesKit/**/*.{h,m,swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5'

  spec.dependency 'RxSwift', '~> 5.0'
  spec.dependency 'Alamofire', '~> 4.0'
  spec.dependency 'GRDB.swift', '~> 4.0'
  spec.dependency 'ObjectMapper', '~> 3.5'
end
