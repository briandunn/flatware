module ProcessSupport
  def child_pids
    `ps -o ppid -o pid`.split("\n")[1..-1].map do |l|
      l.split.map(&:to_i)
    end.inject(Hash.new([])) do |h, (ppid, pid)|
      h.tap { h[ppid] += [pid] }
    end[Process.pid]
  end
end
