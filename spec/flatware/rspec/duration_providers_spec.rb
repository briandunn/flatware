# frozen_string_literal: true

require 'spec_helper'
require 'flatware/rspec/duration_providers'

describe Flatware::RSpec::DurationProviders do
  describe '#lookup' do
    before do
      Flatware::RSpec::DurationProviders.const_set(:MockProvider, mock_provider)
    end

    after do
      Flatware::RSpec::DurationProviders.send(:remove_const, :MockProvider)
    end

    let(:mock_provider) { Class.new }

    it 'returns an object of the specified provider class' do
      expect(described_class.lookup('mock')).to be_a(mock_provider)
    end

    it 'works with a string argument' do
      expect(described_class.lookup(:mock)).to be_a(mock_provider)
    end
  end
end
