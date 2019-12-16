Pod::Spec.new do |s|
  s.name             = 'XRatesKit.swift'
  s.module_name      = 'XRatesKit'
  s.version          = '0.4'
  s.summary          = 'Kit provides latest rates for coins, chart data and historical data for different coins and currencies.'

  s.homepage         = 'https://github.com/horizontalsystems/xrates-kit-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  s.source           = { git: 'https://github.com/horizontalsystems/xrates-kit-ios.git', tag: "#{s.version}" }
  s.social_media_url = 'http://horizontalsystems.io/'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5'

  s.source_files = 'XRatesKit/Classes/**/*'

  s.requires_arc = true

  s.dependency 'Alamofire', '~> 4.0'
  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'RxSwiftExt', '~> 5'
  s.dependency 'GRDB.swift', '~> 4.0'
  s.dependency 'ObjectMapper', '~> 3.5'
end
