#@base
#
# Feature: Windows ASP.NET All-In-One Server Test
#   Tests the windows blog engine server functions
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
  @runner.behavior(:run_script, "install_firefox", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "backup", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "backup_database_check", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "restore", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "backup_to_s3", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "create_scheduled_task", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "delete_scheduled_task", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "register_with_elb", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "deregister_from_elb", @runner.behavior(:s_one))
  @runner.behavior(:run_script, "update_code_svn", @runner.behavior(:s_one))
