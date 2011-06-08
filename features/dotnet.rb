#@base
#
# Feature: Basic Windows Server Test
#   Tests the basic windows
#
# Scenario: windows basic server test, windows quickstart server test
#
# Given A simple deployment
  @runner = VirtualMonkey::DotnetRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)

# Then I should check that monitoring is enabled
  @runner.behavior(:run_script_on_all, 'DB SQLS Download and attach DB')
  @runner.behavior(:run_script_on_all, 'DB SQLS Create login')
  
  @runner.behavior(:run_unified_application_checks, :s_one, 80)

  #@runner.behavior(:run_script_on_all, 'IIS Download application code')
  #@runner.behavior(:run_script_on_all, 'IIS Add connection string')
  #@runner.behavior(:run_script_on_all, 'IIS Switch default website')
  
  #@runner.behavior(:run_script_on_all, 'AWS Register with ELB')
  #@runner.behavior(:run_script_on_all, 'AWS Deregister from ELB')

