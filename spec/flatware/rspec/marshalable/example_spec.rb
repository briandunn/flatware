require 'spec_helper'
require 'flatware/rspec/marshalable/example'
describe Flatware::RSpec::Marshalable::Example do
  it 'caries what is needed to format a backtrace' do
    ::RSpec::Core::Formatters::ExceptionPresenter.new(
      Exception.new,
      described_class.new(
        instance_double(
          ::RSpec::Core::Example,
          execution_result: nil,
          full_description: nil,
          location: nil,
          location_rerun_argument: nil,
          metadata: { shared_group_inclusion_backtrace: [] }
        )
      )
    ).fully_formatted(nil)
  end
end
