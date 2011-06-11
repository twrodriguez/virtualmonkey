#@base
#
# Feature: Base Server Test
#   Tests the base server functions
#
# Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::MonkeySelfTestRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

  @runner.behavior(:raise_exception)

# Then I should stop the servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should test a passing script
  @runner.behavior(:run_script_on_all, "test")

# Then I should test a failing script
  @runner.behavior(:run_script_on_all, "test", true, {"EXIT_VAL" => "text:1"}) { |res| res.is_a?(Exception) }
