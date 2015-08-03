Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '2.5.4'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS and OS X networking framework.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.social_media_url = 'https://twitter.com/AFNetworking'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => s.version, :submodules => true }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.watchos.deployment_target = '2.0'

  s.public_header_files = 'AFNetworking/*.h'
  s.source_files = 'AFNetworking/AFNetworking.h'
  
  pch_AF = <<-EOS
#ifndef TARGET_OS_IOS
  #define TARGET_OS_IOS TARGET_OS_IPHONE
#endif
EOS
  s.prefix_header_contents = pch_AF
  
  s.subspec 'Serialization' do |ss|
    ss.source_files = 'AFNetworking/AFURL{Request,Response}Serialization.{h,m}'
    ss.watchos.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.ios.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.osx.frameworks = 'CoreServices'
  end

  s.subspec 'Security' do |ss|
    ss.source_files = 'AFNetworking/AFSecurityPolicy.{h,m}'
    ss.frameworks = 'Security'
  end

  s.subspec 'Reachability' do |ss|
    ss.source_files = 'AFNetworking/AFNetworkReachabilityManager.{h,m}'
    ss.ios.frameworks = 'SystemConfiguration'
    ss.osx.frameworks = 'SystemConfiguration'
  end

  s.subspec 'NSURLConnection' do |ss|
    ss.dependency 'AFNetworking/Serialization'
    ss.dependency 'AFNetworking/Reachability'
    ss.dependency 'AFNetworking/Security'

    ss.ios.source_files = 'AFNetworking/AFURLConnectionOperation.{h,m}', 'AFNetworking/AFHTTPRequestOperation.{h,m}', 'AFNetworking/AFHTTPRequestOperationManager.{h,m}'
    ss.osx.source_files = 'AFNetworking/AFURLConnectionOperation.{h,m}', 'AFNetworking/AFHTTPRequestOperation.{h,m}', 'AFNetworking/AFHTTPRequestOperationManager.{h,m}'
    ss.watchos.source_files = ''
  end

  s.subspec 'NSURLSession' do |ss|
    ss.dependency 'AFNetworking/Serialization'
    ss.dependency 'AFNetworking/Reachability'
    ss.dependency 'AFNetworking/Security'

    ss.source_files = 'AFNetworking/AFURLSessionManager.{h,m}', 'AFNetworking/AFHTTPSessionManager.{h,m}'
  end

  s.subspec 'UIKit' do |ss|
    ss.ios.deployment_target = '6.0'

    ss.dependency 'AFNetworking/NSURLConnection'
    ss.dependency 'AFNetworking/NSURLSession'

    ss.ios.public_header_files = 'UIKit+AFNetworking/*.h'
    ss.ios.source_files = 'UIKit+AFNetworking'
    ss.osx.source_files = ''
    ss.watchos.source_files = ''
  end
end
