module Flatware
  Job = Struct.new(:id, :args) do
    attr_accessor :worker
    attr_writer :failed
    attr_reader :duration

    def initialize(id, args=[], duration: 0)
      super(id,args || [])
      @duration = duration
    end

    def relative_path
      Pathname(id).expand_path.relative_path_from(Pathname(Dir.pwd)).to_path
    end

    def mtime
      whole_file? && Pathname(id).mtime
    end

    def whole_file?
      not id.include? ':'
    end

    def inspect
      "Job id:#{id} #{@duration}s"
    end

    def failed?
      !!@failed
    end

    def file_path
      id.split(/:\d+$/).first
    end

    def match?(job)
      key = if job.whole_file? then file_path else id end
      key == job.relative_path
    end

    def self.pack(jobs, count)
      duration = -> group do
        group.map(&:duration).reduce(:+) || 0
      end

      groups = [count, jobs.length].min.times.map { [] }

      args = jobs.first.args

      jobs.sort_by(&:duration).reverse.each do |job|
        groups.sort_by(&duration).first.push job
      end

      groups.map do |jobs|
        new jobs.map(&:id), args, duration: duration[jobs]
      end
    end
  end
end
