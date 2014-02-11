include FileUtils::Verbose

namespace :test do
  task :prepare do
    mkdir_p "Tests/AFNetworking Tests.xcodeproj/xcshareddata/xcschemes"
    cp Dir.glob('Tests/Schemes/*.xcscheme'),
       "Tests/AFNetworking Tests.xcodeproj/xcshareddata/xcschemes/"
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
task :test do
  Rake::Task['test:ios'].invoke
  Rake::Task['test:osx'].invoke if is_mavericks_or_above
  puts red("iOS unit tests failed") unless @ios_success
  puts red("OS X unit tests failed") unless @osx_success

  exit 1 unless @ios_success && @osx_success
end

task :default => 'test'


private

def run_tests(scheme, sdk)
  sh("xcodebuild -workspace AFNetworking.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -configuration Release test | xcpretty -c ; exit ${PIPESTATUS[0]}") rescue nil
end

def is_mavericks_or_above
  osx_version = `sw_vers -productVersion`.chomp
  Gem::Version.new(osx_version) >= Gem::Version.new('10.9')
end

def red(string)
 "\033[0;31m! #{string}"
end

