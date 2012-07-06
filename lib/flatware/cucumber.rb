require 'cucumber'
require_relative 'cucumber/runtime'
module Flatware
  module Cucumber
    autoload :Formatter, 'flatware/cucumber/formatter'
    autoload :ProgressString, 'flatware/cucumber/formatter'

    FORMATS = {
      :passed    => '.',
      :failed    => 'F',
      :undefined => 'U',
      :pending   => 'P',
      :skipped   => '-'
    }

    STATUSES = FORMATS.keys

    extend self
    def features
      @features ||= `find features -name '*.feature'`.split "\n"
    end

    def run(feature_files=[], options=[])
      runtime.run feature_files, options
    end

    def runtime
      @runtime ||= Runtime.new
    end
  end
end
