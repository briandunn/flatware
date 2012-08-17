module WaitingSupport
  def wait_until(max_tries=10, &block)
    tries = 0
    until block.call || tries == max_tries do
      tries += 1
      sleep 0.1
    end
  end
end
