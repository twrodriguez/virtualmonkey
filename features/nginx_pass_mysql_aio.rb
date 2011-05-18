# Nginx/Passenger/MySQl AIO Server Template Test

# Given A nginx deployment
  @runner = VirtualMonkey::NginxRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should run nginx checks
  @runner.behavior(:run_nginx_checks)

# Then I should check that ulimit was set correctly
  @runner.probe(".*", "su - mysql -s /bin/bash -c \"ulimit -n\"") { |r,st| r.to_i > 1024 }

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)

# Then I should launch all servers
  @runner.behavior(:reboot_all)

# Then I should run nginx checks
  @runner.behavior(:run_nginx_checks)

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)
  @runner.behavior(:run_logger_audit)
