#@base
#
# Feature: Windows ASP.NET All-In-One Server Test
#   Tests the windows ASP.NET engine server functions
#
# Scenario: windows ASP.NET All-In-One server test
#
# Given A simple deployment
  @runner = VirtualMonkey::SimpleWindowsNetRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should check that monitoring is enabled
#  @runner.behavior(:check_monitoring)

# Then I should check all the scripts in the template
  @runner.behavior(:run_script_on_all, "backup")
  @runner.behavior(:run_script_on_all, "backup_database_check")
  @runner.behavior(:run_script_on_all, "restore")
  @runner.behavior(:run_script_on_all, "backup_to_s3")
  @runner.behavior(:run_script_on_all, "create_scheduled_task")
  @runner.behavior(:run_script_on_all, "delete_scheduled_task")
  @runner.behavior(:run_script_on_all, "register_with_elb")
  @runner.behavior(:run_script_on_all, "deregister_from_elb")
  @runner.behavior(:run_script_on_all, "update_code_svn")
