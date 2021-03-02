# frozen_string_literal: true

require 'spec_helper'
require 'flatware/configuration'

describe Flatware::Configuration do
  it 'defaults to noop procs' do
    expect do
      Flatware.configuration.before_fork.call
      Flatware.configuration.after_fork.call(nil)
    end.to_not raise_error
  end
end
