include FileUtils::Verbose

namespace :test do
  def run_tests(scheme, sdk)
    sh("xcodebuild -workspace AFNetworking.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -configuration Release test | xcpretty -c ; exit ${PIPESTATUS[0]}") rescue nil
  end

  task :prepare do
    mkdir_p "Tests/AFNetworking Tests.xcodeproj/xcshareddata/xcschemes"
    cp Dir.glob('Tests/Schemes/*.xcscheme'), "Tests/AFNetworking Tests.xcodeproj/xcshareddata/xcschemes/"
  end

  desc "Run the AFNetworking Tests for iOS"
  task :ios => :prepare do
    run_tests('iOS Tests', 'iphonesimulator')
    @ios_success = $?.success?
  end

  desc "Run the AFNetworking Tests for Mac OS X"
  task :osx => :prepare do
    run_tests('OS X Tests', 'macosx')
    @osx_success = $?.success?
  end
end

desc "Run the AFNetworking Tests for iOS & Mac OS X"
task :test => ['test:ios', 'test:osx'] do
  puts "\033[0;31m! iOS unit tests failed" unless @ios_success
  puts "\033[0;31m! OS X unit tests failed" unless @osx_success
  if @ios_success && @osx_success
    puts "\033[0;32m** All tests executed successfully"
  else
    exit 1
  end
end

task :default => 'test'

