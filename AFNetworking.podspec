Pod::Spec.new do
  name     'AFNetworking'
  version  '0.7.0'
  summary  'A delightful iOS and OS X networking framework'
  homepage 'https://github.com/gowalla/AFNetworking'
  authors  'Mattt Thompson' => 'm@mattt.me', 'Scott Raymond' => 'sco@gowalla.com'
  source   :git      => 'https://github.com/gowalla/AFNetworking.git',
           :tag      => '0.7.0'
  
  platforms 'iOS', 'OSX'
  sdk '>= 4.0'
  
  source_files 'AFNetworking'

  xcconfig 'OTHER_LDFLAGS' => '-ObjC ' \
                              '-all_load ' \
                              '-l z'
  dependency 'JSONKit'
  
  doc_bin 'appledoc'
  doc_options '--project-name' => 'AFNetworking', '--project-company' => 'Gowalla', '--company-id' => 'com.gowalla'
end