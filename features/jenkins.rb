#@base
#
# Feature: Base Server Test
#   Tests the base server functions
#
# Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::JenkinsRunner.new(ENV['DEPLOYMENT'])

  @runner.set_var(:set_variation_lineage)
  @runner.set_var(:set_variation_container)
  @runner.set_var(:set_variation_storage_type)

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

  @runner.behavior(:do_prep)

  @runner.behavior(:test_multicloud)

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)

# Then I should reboot the servers
  @runner.behavior(:reboot_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)

  @runner.behavior(:check_app_monitoring)

  @runner.behavior(:test_http)

  @runner.behavior(:run_logger_audit)
