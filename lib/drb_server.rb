require 'drb/drb'
require 'rspec'
URI = "druby://localhost:8989"
class Runner
  def run(args, error_stream, out_stream)
    RSpec::Core::ConfigurationOptions.new(args).tap do |config|
      config.parse_options
    end.configure(RSpec::configuration)
    puts RSpec::configuration.files_to_run.inspect
    RSpec::configuration.files_to_run.each do |spec|
      puts "running #{spec}"
    end
    0
  end
end
DRb.start_service URI, Runner.new
DRb.thread.join
