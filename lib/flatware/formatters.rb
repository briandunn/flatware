module Flatware
  module Formatters
    def self.load_by_name(runner, names)
      formatters = names.map do |name|
        require "flatware/formatters/#{runner}/#{name}"
        namespace = const_get({rspec: 'RSpec', cucumber: 'Cucumber'}.fetch(runner))
        klass = namespace.const_get name.capitalize
        klass.new $stdout, $stderr
      end
      Broadcaster.new formatters
    end
  end

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
