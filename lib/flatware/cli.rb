require 'thor'
module Flatware
  class CLI < Thor
    desc "mux", "splits your current tmux pane into worker panes. Runs workers in them."
    def mux
      processors.times do |env_number|
        command = <<-SH
          TEST_ENV_NUMBER=#{env_number} bundle exec rake db:create db:test:prepare && bundle exec flatware work
        SH
        system <<-SH
          tmux send-keys -t `tmux split-window -h -P` "#{command}" C-m
        SH
      end
      system "tmux select-layout even-horizontal"
      dispatch
    end

    desc "dispatch", "fire up the dispatcher to distribute tests"
    def dispatch
      Dispatcher.dispatch!
    end

    desc "work", "request and perform work from a dispatcher"
    def work
     Worker.listen!
    end

    private

    def processors
      @processors ||= `hostinfo`.match(/^(?<processors>\d+) processors are logically available\.$/)[:processors].to_i
    end
  end
end
