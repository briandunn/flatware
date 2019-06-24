require 'timeout'
module WaitingSupport
  def wait(pid)
    Timeout.timeout Aruba.config.exit_timeout do
      Process.wait pid
    end
  end
end
