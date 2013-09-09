Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '2.0.0-RC3'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS and OS X networking framework.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me', 'Scott Raymond' => 'sco@scottraymond.net' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => '2.0.0-RC3', :submodules => true }
  s.requires_arc = true

  s.ios.deployment_target = '5.0'
  s.ios.frameworks = 'MobileCoreServices', 'SystemConfiguration', 'Security', 'CoreGraphics'

  s.osx.deployment_target = '10.7'
  s.osx.frameworks = 'CoreServices', 'SystemConfiguration', 'Security'

  s.subspec 'Core' do |ss|
    ss.source_files = 'AFNetworking'

    ss.dependency 'AFNetworking/Serialization'
    ss.dependency 'AFNetworking/Reachability'
    ss.dependency 'AFNetworking/Security'

    ss.dependency 'AFNetworking/NSURLConnection'
  end

  s.subspec 'Serialization' do |ss|
    ss.source_files = 'AFNetworking/AFURL{Request,Response}Serialization.{h,m}'
  end

  s.subspec 'Security' do |ss|
    ss.source_files = 'AFNetworking/AFSecurityPolicy.{h,m}'
  end

  s.subspec 'Reachability' do |ss|
    ss.source_files = 'AFNetworking/AFNetworkReachabilityManager.{h,m}'
  end

  s.subspec 'NSURLConnection' do |ss|
    ss.source_files = 'AFNetworking/AFURLConnectionOperation.{h,m}', 'AFNetworking/AFHTTPRequestOperation.{h,m}', 'AFNetworking/AFHTTPRequestOperationManager.{h,m}'
  end

  s.subspec 'NSURLSession' do |ss|
    s.ios.deployment_target = '7.0'
    s.osx.deployment_target = '10.9'

    ss.source_files = 'AFNetworking/AFURLSessionManager.{h,m}', 'AFNetworking/AFHTTPSessionManager.{h,m}'
  end

  s.subspec 'UIKit+AFNetworking' do |ss|
    ss.source_files = 'UIKit+AFNetworking'
  end
end
