require 'spec_helper'
require 'flatware/rspec/marshalable/example'
describe Flatware::RSpec::Marshalable::Example do
  def stub_execution_result(exception)
    instance_double(
      RSpec::Core::Example::ExecutionResult,
      exception: exception,
      finished_at: Time.now,
      run_time: 0,
      started_at: Time.now,
      status: :failed
    )
  end

  it 'carries what is needed to format a backtrace' do
    exception = Exception.new
    RSpec::Core::Formatters::ExceptionPresenter.new(
      exception,
      described_class.new(
        instance_double(
          RSpec::Core::Example,
          execution_result: stub_execution_result(exception),
          full_description: nil,
          location: nil,
          location_rerun_argument: nil,
          metadata: { shared_group_inclusion_backtrace: [] }
        )
      )
    ).fully_formatted(nil)
  end

  it 'does not carry constant references in exceptions' do
    const = stub_const('A::Constant::Not::Likely::Loaded::In::Sink', Class.new(RuntimeError))
    wrapper_const = stub_const('Another::Constant::Not::Likely::Loaded::In::Sink', Class.new(RuntimeError))
    caught_exception = begin
      begin
        raise const, 'something bad happened'
      rescue RuntimeError => e
        # raise a second exception so that Exception#cause is set up
        raise wrapper_const, e
      end
    rescue RuntimeError => e
      e
    end

    message = described_class.new(
      instance_double(
        RSpec::Core::Example,
        execution_result: stub_execution_result(caught_exception),
        full_description: nil,
        location: nil,
        location_rerun_argument: nil,
        metadata: {}
      )
    )

    result_exception = message.execution_result.exception

    expect(result_exception).to be_an_instance_of(Flatware::SerializedException)
    expect(result_exception.class.to_s).to eq(wrapper_const.to_s)
    expect(result_exception.class).to_not be_an_instance_of(wrapper_const)

    expect(result_exception.cause).to be_an_instance_of(Flatware::SerializedException)
    expect(result_exception.cause.class.to_s).to eq(const.to_s)
    expect(result_exception.cause.class).to_not be_an_instance_of(const)
  end
end
