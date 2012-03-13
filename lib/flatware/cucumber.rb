require 'cucumber'
module Flatware
  module Cucumber
    extend self
    def features
      `find features -name '*.feature' | xargs grep -Hn Scenario | cut -f '1,2' -d ':'`.split "\n"
    end

    def run(options, out, error)
      ::Cucumber::Cli::Main.new(Array(options), out, error).execute!
    end
  end
end
