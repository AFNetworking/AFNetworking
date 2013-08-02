Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '2.0.0-RC1'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS and OS X networking framework.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me', 'Scott Raymond' => 'sco@gowalla.com' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => '2.0.0-RC1' }
  s.requires_arc = true

  s.ios.deployment_target = '7.0'
  s.ios.frameworks = 'MobileCoreServices', 'SystemConfiguration', 'Security', 'CoreGraphics'

  s.osx.deployment_target = '10.9'
  s.osx.frameworks = 'CoreServices', 'SystemConfiguration', 'Security'

  s.subspec 'Core' do |ss|
    ss.source_files = 'AFNetworking'
  end

  s.subspec 'UIKit+AFNetworking' do |ss|
    ss.source_files = 'UIKit+AFNetworking'
  end
end
