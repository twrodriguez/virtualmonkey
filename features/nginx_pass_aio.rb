#@lamp_test
#
#Feature: Nginx Passenger AIO Server Template Test
#  Tests the deployment
#
#Scenario: Nginx Passenger AIO Server Template Test
#
# Given A AIO deployment
  @runner = VirtualMonkey::OnboardingRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should run Onboarding checks
  @runner.behavior(:run_onboarding_checks)

# Then I should check that ulimit was set correctly
  @runner.probe(".*", "su - mysql -s /bin/bash -c \"ulimit -n\"") { |r,st| r.to_i > 1024 }

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)
  @runner.behavior(:check_passenger_monitoring)
#  @runner.behavior(:run_logger_audit)
