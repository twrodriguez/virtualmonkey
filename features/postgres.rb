#@postgres
#Feature: PostgreSQL 9.0
#  Tests the RightScale premium ServerTemplate
#
# PHASE 1) Bootstrap and test promote
#
# Given A PostgreSQL deployment
  @runner = VirtualMonkey::PostgresRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should set a variation lineage
  @runner.set_var(:set_variation_lineage)

# Then I should set a variation stripe count of "1"
  @runner.set_var(:set_variation_stripe_count, 1)

# Then I should set a variation DNS
  @runner.set_var(:setup_dns, "virtualmonkey_shared_resources") # DNSMadeEasy

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should test promotion operations on the deployment
  @runner.behavior(:run_promotion_operations)

# Then I should run standard checks
  @runner.behavior(:run_checks)

# Then I should check that ulimit was set correctly
  @runner.probe(".*", "su - postgres -s /bin/bash -c \"ulimit -n\"") { |r, st| r.to_i > 1024 }

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)

#
# PHASE 2) Reboot
#

# Then I should test reboot operations on the deployment
  @runner.behavior(:run_reboot_operations)

#
# PHASE 3) Additional Tests
#

# Then I should run a restore using OPT_DB_RESTORE_TIMESTAMP_OVERRIDE
  @runner.behavior(:run_restore_with_timestamp_override)

# 
# PHASE 4) Terminate
#

# Then I should terminate the servers
  @runner.behavior(:stop_all, true)

# Then I should release the DNS
  @runner.behavior(:release_dns)
