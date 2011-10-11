Pod::Spec.new do
  name     'AFNetworking'
  version  '0.6.1'
  summary  'A delightful iOS networking library with NSOperations and block-based callbacks'
  homepage 'https://github.com/gowalla/AFNetworking'
  authors  'Mattt Thompson' => 'm@mattt.me', 'Scott Raymond' => 'sco@gowalla.com'
  source   :git      => 'https://github.com/gowalla/AFNetworking.git',
           :tag      => '0.6.1'
  
  platforms 'iOS'
  sdk '>= 4.0'
  
  source_files 'AFNetworking'

  xcconfig 'OTHER_LDFLAGS' => '-ObjC ' \
                              '-all_load ' \
                              '-l z'
  dependency 'JSONKit'
  
  doc_bin 'appledoc'
  doc_options '--project-name' => 'AFNetworking', '--project-company' => 'Gowalla', '--company-id' => 'com.gowalla'
end