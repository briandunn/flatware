# frozen_string_literal: true

Aruba.configure do |config|
  config.working_directory = "tmp/aruba#{ENV['TEST_ENV_NUMBER']}"
  config.exit_timeout = 3
  config.io_wait_timeout = config.startup_wait_time = config.exit_timeout
end
