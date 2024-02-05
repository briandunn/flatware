Aruba.configure do |config|
  config.working_directory = "tmp/aruba#{ENV.fetch('TEST_ENV_NUMBER', nil)}"
  config.startup_wait_time = 0.1
  config.io_wait_timeout = config.exit_timeout = 3
end
