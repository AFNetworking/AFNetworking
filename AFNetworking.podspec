Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '0.10.1'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS and OS X networking framework.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.authors  = {'Mattt Thompson' => 'm@mattt.me', 'Scott Raymond' => 'sco@scottraymond.net'}
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => '0.10.1' }
  s.source_files = 'AFNetworking'
  s.framework = 'SystemConfiguration'
  s.prefix_header_contents = "#import <SystemConfiguration/SystemConfiguration.h>"
end
