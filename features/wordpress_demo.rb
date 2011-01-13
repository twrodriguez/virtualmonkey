#
# This is a test for a Wordpress Demo ServerTemplate which is based on the LAMP AIO
#
# Given A LAMP deployment
  @runner = VirtualMonkey::LampRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should run LAMP checks
#  @runner.behavior(:run_lamp_checks)

# Then I should run mysql checks
#  @runner.behavior(:run_checks)

# Wordpress application checks
  @runner.behavior(:test_http_response, "html", "http://#{@runner.deployment.servers.first.dns_name}/wp-login.php", 80)

# Then I should check that monitoring is enabled
#  @runner.behavior(:check_monitoring)
