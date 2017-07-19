module Flatware
  class Stats
    FILE_NAME='.flatware_stats.yml'
    attr_reader :stats

    def initialize(stats)
      @stats = stats
    end

    def merge(other)
      stats.merge(other.stats)
    end

    def resolve(jobs)
      jobs.flat_map do |job|
        args = job.args
        matching_stats = stats.map do |id, duration|
          Job.new(id, args, duration: duration)
        end.select do |stat|
          stat.match?(job)
        end
        matching_stats.any? ? matching_stats : [Job.new(job.id, args, duration: 1)]
      end
    end

    def self.write(checkpoints)
      File.write(FILE_NAME, YAML.dump(read.merge(new(checkpoints.map(&:to_stats).reduce(:merge) || {}))))
    end

    def self.read
      stats = YAML.load_file(FILE_NAME) rescue {}
      new stats
    end
  end
end
