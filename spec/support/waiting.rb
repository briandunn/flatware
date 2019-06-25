require 'timeout'
module WaitingSupport
  def wait(pid, timeout=3)
    Timeout.timeout 3 do
      Process.wait pid
    end
  end
end
