require 'cucumber'

module Flatware
  module Cucumber
    class Runtime < ::Cucumber::Runtime
      attr_accessor :configuration, :loader
      attr_reader :out, :err, :visitor

      def initialize(out = StringIO.new, err = out)
        @out = out
        @err = err
        super(default_configuration)
        load_step_definitions
        @results = Results.new(configuration)
      end

      def default_configuration
        config = ::Cucumber::Cli::Configuration.new
        config.parse! []
        config
      end

      def run(feature_files = [], options = [])
        @loader = nil
        options = [
          Array(feature_files),
          %w[--format Flatware::Cucumber::Formatter],
          options
        ].reduce(:+)

        configure(::Cucumber::Cli::Main.new(options, out, err).configuration)

        self.visitor = configuration.build_tree_walker(self)
        visitor.visit_features(features)
        results
      end
    end
  end
end
