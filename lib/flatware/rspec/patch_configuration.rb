::RSpec::Core::Configuration.prepend(Module.new do
  def command
    'rspec'
  end
end)
