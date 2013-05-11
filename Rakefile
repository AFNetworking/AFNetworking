namespace :test do
  desc "Run the AFNetworking Tests for iOS"
  task :ios do
    system("xctool -workspace AFNetworking.xcworkspace -scheme 'iOS Tests' test -test-sdk iphonesimulator")
  end
  
  desc "Run the AFNetworking Tests for Mac OS X"
  task :osx do
    system("xctool -workspace AFNetworking.xcworkspace -scheme 'OS X Tests' test -test-sdk macosx -sdk macosx")
  end
end

desc "Run the AFNetworking Tests for iOS & Mac OS X"
task :test => ['test:ios', 'test:osx']

task :default => 'test'
