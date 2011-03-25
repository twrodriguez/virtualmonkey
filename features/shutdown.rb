#@base
#
# Feature: Base Server Test
#   Tests the base server functions
#
# Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::ShutdownRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should shutdown server using operational script
  @runner.behavior(:run_script!, "shutdown", {'wait' => false})

# Then the server should become terminated
  @runner.behavior(:wait_for_all, "stopped")
