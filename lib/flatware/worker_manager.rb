# frozen_string_literal: true

module Flatware
  # Manages the available workers to execute tests on
  class WorkerManager
    attr_reader :sink, :runner, :id

    attr_reader :workers

    def initialize(count:, runner:, sink:)
      @runner = runner
      @sink = sink
      @stopped = false

      @workers = Set.new
      @worker_pids = {}
      count.times do |i|
        register(i)
      end
    end

    def stop
      @stopped = true
    end

    def spawn
      Flatware.configuration.before_fork.call
      trap_signals
      respawn
    end

    def respawn
      worker_ids = @workers - @worker_pids.keys
      worker_ids.each do |id|
        pid = fork do
          DRb.stop_service
          $0 = "flatware worker #{id}"
          ENV['TEST_ENV_NUMBER'] = id.to_s
          Flatware.configuration.after_fork.call(id)
          Worker.new(id, @runner, @sink).listen
        end

        @worker_pids[id] = pid
      end
    end

    def register(worker_id)
      @workers << worker_id
    end

    def delete(worker_id)
      @workers.delete(worker_id)
    end

    def count
      @workers.length
    end

    def trap_signals
      Thread.main[:child_signals] = Queue.new

      Thread.new(&method(:handle_signals))

      trap 'CHLD' do
        if Thread.main[:child_signals]
          Thread.main[:child_signals] << :chld
        end
      end
    end

    def handle_signals
      while !@stopped
        Thread.main[:child_signals].pop
        reap_workers
        respawn unless @stopped
      end
    end

    def reap_workers
      @worker_pids.reject! do |id, pid|
        # Non-blocking wait for process to die
        begin
          status = Process.wait(pid, Process::WNOHANG)
          case status
          when nil
            # Process is still running
            false
          when pid
            # Collected status of this pid
            true
          end
        rescue Errno::ECHILD
          # Child process has already terminated
          true
        end
      end
    end
  end
end
