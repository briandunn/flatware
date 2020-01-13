require 'pathname'
require 'rspec'
require 'flatware'
require 'flatware/cucumber'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Pathname(__FILE__).dirname.glob('support/**/*.rb').sort.each { |f| require f }

RSpec.configure do |config|
  config.include WaitingSupport
  config.raise_errors_for_deprecations!
  config.around :each, :verbose do |example|
    Flatware.verbose = true
    example.run
    Flatware.verbose = false
  end
end
