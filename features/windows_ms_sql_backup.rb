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
  @runner.behavior(:check_monitoring)


# Then I should check that monitoring is enabled
  @runner.behavior(:run_script_on_all, "EBS Create data and log volumes")
  @runner.behavior(:run_script_on_all, "sql_db_check")
  @runner.behavior(:run_script_on_all, "DB SQLS Configure tempdb")
  @runner.behavior(:run_script_on_all, "tempdb_check")
  @runner.behavior(:run_script_on_all, "DB SQLS create user")
  @runner.behavior(:run_script_on_all, "newuser_check")
  @runner.behavior(:run_script_on_all, "load_db")
  @runner.behavior(:run_script_on_all, "log_repair_before")
  @runner.behavior(:run_script_on_all, "DB SQLS Repair log files")
  @runner.behavior(:run_script_on_all, "log_repair_after")
  @runner.behavior(:run_script_on_all, "EBS Backup data and log volumes")
  @runner.behavior(:run_script_on_all, "DB SQLS DISABLE SERVER - snapshot, detach and delete volumes")

