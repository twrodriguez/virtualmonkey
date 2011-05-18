#@base
#
#Feature: Base Server Test
#  Tests the base server functions
#
#Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::SimpleRunner.new(ENV['DEPLOYMENT'])

## Then I should stop the servers
# runner.behavior(:stop_all)

## Then I should relaunch all servers
# runner.behavior(:relaunch_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should perform start stop operations.
  @runner.behavior(:perform_start_stop_operations)
#  @runner.behavior(:run_logger_audit)
