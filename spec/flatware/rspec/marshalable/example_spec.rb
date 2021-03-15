require 'spec_helper'
require 'flatware/rspec/marshalable/example'
describe Flatware::RSpec::Marshalable::Example do
  def stub_execution_result(exception)
    instance_double(
      ::RSpec::Core::Example::ExecutionResult,
      exception: exception,
      finished_at: Time.now,
      run_time: 0,
      started_at: Time.now,
      status: :failed
    )
  end

  it 'caries what is needed to format a backtrace' do
    exception = Exception.new
    ::RSpec::Core::Formatters::ExceptionPresenter.new(
      exception,
      described_class.new(
        instance_double(
          ::RSpec::Core::Example,
          execution_result: stub_execution_result(exception),
          full_description: nil,
          location: nil,
          location_rerun_argument: nil,
          metadata: { shared_group_inclusion_backtrace: [] }
        )
      )
    ).fully_formatted(nil)
  end

  it 'does not cary constant references in exceptions' do
    const = stub_const('A::Constant::Not::Likely::Loaded::In::Sink', Class.new(RuntimeError))
    message = described_class.new(
      instance_double(
        ::RSpec::Core::Example,
        execution_result: stub_execution_result(const.new),
        full_description: nil,
        location: nil,
        location_rerun_argument: nil,
        metadata: {}
      )
    )

    expect(message.execution_result.exception.class.to_s).to eq(const.to_s)
    expect(message.execution_result.exception.class).to_not be_an_instance_of(const)
  end
end
