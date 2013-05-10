namespace :test do
  desc "Run the AFNetworking Tests for iOS"
  task :ios do
    system('xctool -workspace AFNetworking.xcworkspace -scheme AFNetworkingTests test -test-sdk iphonesimulator')
  end
  
  desc "Run the AFNetworking Tests for Mac OS X"
  task :osx do
    system('xctool -workspace AFNetworking.xcworkspace -scheme AFNetworkingFrameworkTests test -test-sdk macosx -sdk macosx')
  end
  
  desc "Run the AFNetworking Tests for iOS & Mac OS X"
  task :all => ['test:ios', 'test:osx']
end

task :default => 'test:all'
