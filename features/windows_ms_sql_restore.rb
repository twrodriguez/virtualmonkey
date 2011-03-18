#@base
#
# Feature: Windows MS SQL Server Test
#   Tests the windows MS SQL server functions
#
# Scenario: windows MS SQL server test
#
# Given A simple deployment
  @runner = VirtualMonkey::SimpleWindowsSQLRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should check that monitoring is enabled
#  @runner.behavior(:check_monitoring)

# Then I should check all the scripts in the template
  @runner.behavior(:run_script, "DB SQLS restore data volume", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "sql_db_check", @runner.behavior(:s_one))

