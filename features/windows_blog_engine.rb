#@base
#
# Feature: Windows Blog Engine Server Test
#   Tests the windows blog engine server functions
#
# Scenario: windows blog engine server test
#
# Given A simple deployment
  @runner = VirtualMonkey::SimpleWindowsBlogRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should check that monitoring is enabled
#  @runner.behavior(:check_monitoring)

# Then I should check all the scripts in the template
  @runner.behavior(:run_script, "backup_database", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "backup_database_check", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "drop_database", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "restore_database", @runner.behavior(:s_one))
