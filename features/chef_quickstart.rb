#@rightlink
#Feature: RightLink Feature Tests
#
# Make sure rightlink supports the expected functionality 
#
# Scenario: The RightLink Test template should go operational
# Given A simple deployment
  @runner = VirtualMonkey::SimpleRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)
