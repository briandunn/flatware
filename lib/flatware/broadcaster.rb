module Flatware
  class Broadcaster
    attr_reader :formatters

    def initialize(formatters)
      @formatters = formatters
    end

    def method_missing(name, *args)
      formatters.each do |formatter|
        formatter.send name, *args if formatter.respond_to? name
      end
    end
  end
end
