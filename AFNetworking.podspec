Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '1.0'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS and OS X networking framework.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.authors  = {'Mattt Thompson' => 'm@mattt.me', 'Scott Raymond' => 'sco@gowalla.com'}
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => '1.0RC3' }
  s.source_files = 'AFNetworking'
  s.requires_arc = true

  s.framework = 'SystemConfiguration'
  s.prefix_header_contents = "#import <SystemConfiguration/SystemConfiguration.h>"
end
