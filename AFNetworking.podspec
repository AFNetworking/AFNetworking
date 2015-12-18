Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '3.0.4'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS and OS X networking framework.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.social_media_url = 'https://twitter.com/AFNetworking'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => s.version, :submodules => true }
  s.requires_arc = true
  
  s.public_header_files = 'AFNetworking/AFNetworking.h'
  s.source_files = 'AFNetworking/AFNetworking.h'
  
  pch_AF = <<-EOS
#ifndef TARGET_OS_IOS
  #define TARGET_OS_IOS TARGET_OS_IPHONE
#endif

#ifndef TARGET_OS_WATCH
  #define TARGET_OS_WATCH 0
#endif

#ifndef TARGET_OS_TV
  #define TARGET_OS_TV 0
#endif
EOS
  s.prefix_header_contents = pch_AF
  
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  
  s.subspec 'Serialization' do |ss|
    ss.source_files = 'AFNetworking/AFURL{Request,Response}Serialization.{h,m}'
    ss.public_header_files = 'AFNetworking/AFURL{Request,Response}Serialization.h'
    ss.watchos.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.ios.frameworks = 'MobileCoreServices', 'CoreGraphics'
    ss.osx.frameworks = 'CoreServices'
  end

  s.subspec 'Security' do |ss|
    ss.source_files = 'AFNetworking/AFSecurityPolicy.{h,m}'
    ss.public_header_files = 'AFNetworking/AFSecurityPolicy.h'
    ss.frameworks = 'Security'
  end

  s.subspec 'Reachability' do |ss|
    ss.ios.deployment_target = '7.0'
    ss.osx.deployment_target = '10.9'
    ss.tvos.deployment_target = '9.0'

    ss.source_files = 'AFNetworking/AFNetworkReachabilityManager.{h,m}'
    ss.public_header_files = 'AFNetworking/AFNetworkReachabilityManager.h'

    ss.frameworks = 'SystemConfiguration'
  end

  s.subspec 'NSURLSession' do |ss|
    ss.dependency 'AFNetworking/Serialization'
    ss.ios.dependency 'AFNetworking/Reachability'
    ss.osx.dependency 'AFNetworking/Reachability'
    ss.tvos.dependency 'AFNetworking/Reachability'
    ss.dependency 'AFNetworking/Security'

    ss.source_files = 'AFNetworking/AF{URL,HTTP}SessionManager.{h,m}'
    ss.public_header_files = 'AFNetworking/AF{URL,HTTP}SessionManager.h'
  end

  s.subspec 'UIKit' do |ss|
    ss.ios.deployment_target = '7.0'
    ss.tvos.deployment_target = '9.0'
    ss.dependency 'AFNetworking/NSURLSession'

    ss.public_header_files = 'UIKit+AFNetworking/*.h'
    ss.source_files = 'UIKit+AFNetworking'
  end
end
