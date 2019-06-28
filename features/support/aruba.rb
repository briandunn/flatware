Aruba.configure do |config|
  config.working_directory = "tmp/aruba#{ENV['TEST_ENV_NUMBER']}"
  config.startup_wait_time = 0.1
  config.io_wait_timeout = config.exit_timeout = 3
end
