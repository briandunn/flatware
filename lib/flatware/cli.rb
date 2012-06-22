require 'thor'
module Flatware
  class CLI < Thor
    class_option :log, :aliases => "-l", :type => :boolean, :desc => "Print debug messages to $stderr"

    desc "mux", "splits your current tmux pane into worker panes. Runs workers in them."
    def mux
      processors.times do |env_number|
        command = <<-SH
          TEST_ENV_NUMBER=#{env_number} bundle exec ../../bin/flatware work && exit
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

    default_task :default
    desc "default", "starts workers and gives them work"
    def default
      Flatware.verbose = options[:log]
      processors.times do
        fork do
          log "work"
          Worker.listen!
        end
      end
      fork do
        log "dispatch"
        dispatch
      end
      log "bossman"
      Sink.start_server
      Process.waitall
    end

    private

    def log(*args)
      Flatware.log(*args)
    end

    def processors
      @processors ||= `hostinfo`.match(/^(?<processors>\d+) processors are logically available\.$/)[:processors].to_i
    end
  end
end
