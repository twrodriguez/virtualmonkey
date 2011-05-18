#@image_tester
#
# Feature: Image Tester
#   Tests that images are good
#
# Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::SimpleRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")
#  @runner.behavior(:run_logger_audit)
