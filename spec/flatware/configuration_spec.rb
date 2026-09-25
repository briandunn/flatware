# frozen_string_literal: true

require 'spec_helper'
require 'flatware/configuration'

describe Flatware::Configuration do
  it 'defaults to noop procs' do
    expect do
      Flatware.configuration.before_fork.call
      Flatware.configuration.after_fork.call(nil)
      Flatware.configuration.after_forks_complete.call
    end.to_not raise_error
  end

  describe '#after_forks_complete' do
    after { Flatware.configuration.reset! }

    it 'stores and returns the given block' do
      called = false
      Flatware.configure do |config|
        config.after_forks_complete { called = true }
      end
      Flatware.configuration.after_forks_complete.call
      expect(called).to be true
    end
  end
end
