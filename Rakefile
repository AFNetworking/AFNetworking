# Reference from https://github.com/soffes/sskeychain
class String
  def self.colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def red
    self.class.colorize(self, 31)
  end

  def green
    self.class.colorize(self, 32)
  end
end

def test_project(project, target, verbose = false)
  command = "xcodebuild -project \"#{project}\" -target \"#{target}\" -sdk iphonesimulator -configuration Debug RUN_UNIT_TEST_WITH_IOS_SIM=YES 2>&1"
  IO.popen(command) do |io|
    out = 0
    while line = io.gets do
      if verbose
        puts line
      else
        if line =~ /Started running tests with ios-sim/i
          out = out + 1
        end
        
        if out > 0
          case line
          when /failed/i, /error/i
            puts line.red
          when /passed/i
            puts line.green
          else
            puts line
          end
        end
        
        if line =~ /Finished running tests with ios-sim/i
          out = out - 1
        end
      end
      
      if line == "** BUILD SUCCEEDED **\n"
        return 0
      elsif line == "** BUILD FAILED **\n"
        return 1
      end
    end
  end
end

desc 'Run the tests'
task :test do
  verbose = ENV['VERBOSE']
  ios = test_project('Example/AFNetworking iOS Example.xcodeproj', 'AFNetworking iOS Tests', verbose)

  puts "\n\n\n" if verbose
  puts "iOS: #{ios == 0 ? 'PASSED'.green : 'FAILED'.red}"
  exit(ios)
end

task :default => :test
