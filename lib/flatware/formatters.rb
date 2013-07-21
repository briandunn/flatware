module Flatware
  module Formatters
    def self.load_by_name(name)
      require "flatware/formatters/#{name}"
      klass = const_get name.capitalize
      klass.new $stdout, $stderr
    end
  end
end
