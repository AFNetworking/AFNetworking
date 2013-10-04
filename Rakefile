namespace :test do
  task :prepare do
    system(%Q{mkdir -p "Tests/AFNetworking Tests.xcodeproj/xcshareddata/xcschemes" && cp Tests/Schemes/*.xcscheme "Tests/AFNetworking Tests.xcodeproj/xcshareddata/xcschemes/"})
  end

  desc "Run the AFNetworking Tests for iOS"
  task :ios => :prepare do
    $ios_success = system("xctool -workspace AFNetworking.xcworkspace -scheme 'iOS Tests' -sdk iphonesimulator -configuration Release test -test-sdk iphonesimulator")
  end

  desc "Run the AFNetworking Tests for Mac OS X"
  task :osx => :prepare do
    $osx_success = system("xctool -workspace AFNetworking.xcworkspace -scheme 'OS X Tests' -sdk macosx -configuration Release test -test-sdk macosx")
  end
end

desc "Run the AFNetworking Tests for iOS & Mac OS X"
task :test => ['test:ios', 'test:osx'] do
  puts "\033[0;31m! iOS unit tests failed" unless $ios_success
  puts "\033[0;31m! OS X unit tests failed" unless $osx_success
  if $ios_success && $osx_success
    puts "\033[0;32m** All tests executed successfully"
  else
    exit(-1)
  end
end

task :default => 'test'
