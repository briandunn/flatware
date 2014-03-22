$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'flatware'
require 'flatware/cucumber'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include ProcessSupport
  config.include WaitingSupport
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.around verbose: true do |example|
    Flatware.verbose = true
    example.run
    Flatware.verbose = false
  end
end
