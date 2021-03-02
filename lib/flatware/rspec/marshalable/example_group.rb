module Flatware
  module RSpec
    module Marshalable
      ExampleGroup = Struct.new(:location) do
        def initialize(rspec_example_group)
          super(rspec_example_group.location)
        end
      end
    end
  end
end
