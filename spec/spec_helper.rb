$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'flatware'
require 'flatware/cucumber'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include WaitingSupport
  config.raise_errors_for_deprecations!
  config.after(:each) do
    Flatware.configuration.reset!
  end
  config.before :each do
    allow(::RSpec).to receive_messages(
      world: instance_double(::RSpec::Core::World),
      configuration: instance_double(::RSpec::Core::Configuration)
    )
  end
  config.around :each, :verbose do |example|
    Flatware.verbose = true
    example.run
    Flatware.verbose = false
  end
end
