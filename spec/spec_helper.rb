require 'pathname'
require 'rspec'
require 'flatware'
require 'flatware/cucumber'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[Pathname(__FILE__).dirname.join('support/**/*.rb')]
  .sort
  .each { |f| require f }

RSpec.configure do |config|
  config.include WaitingSupport
  config.raise_errors_for_deprecations!
  config.example_status_persistence_file_path = 'tmp/examples.txt'
  config.around :each, :verbose do |example|
    Flatware.verbose = true
    example.run
    Flatware.verbose = false
  end
end
