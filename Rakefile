namespace :test do
  desc "Run the AFNetworking Tests for iOS"
  task :ios do
    $ios_success = system("xctool -workspace AFNetworking.xcworkspace -scheme 'iOS Tests' test -test-sdk iphonesimulator -configuration Release")
  end
  
  desc "Run the AFNetworking Tests for Mac OS X"
  task :osx do
    $osx_success = system("xctool -workspace AFNetworking.xcworkspace -scheme 'OS X Tests' test -test-sdk macosx -sdk macosx -configuration Release")
  end
end

desc "Run the AFNetworking Tests for iOS & Mac OS X"
task :test => ['test:ios', 'test:osx'] do
  puts "\033[0;31m!! iOS unit tests failed" unless $ios_success
  puts "\033[0;31m!! OS X unit tests failed" unless $osx_success
  if $ios_success && $osx_success
    puts "\033[0;32m** All tests executed successfully"
  else
    exit(-1)
  end
end

task :default => 'test'
