Pod::Spec.new do |s|
  s.name     = 'AFNetworking'
  s.version  = '0.10.0'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS and OS X networking framework'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.authors  = {'Mattt Thompson' => 'm@mattt.me', 'Scott Raymond' => 'sco@gowalla.com'}
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => '0.10.0' }
  s.source_files = 'AFNetworking'
  s.clean_paths = ['iOS Example', 'Mac Example', 'AFNetworking.xcworkspace']
  s.framework = 'SystemConfiguration'
end
