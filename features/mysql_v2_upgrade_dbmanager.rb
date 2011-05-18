#@mysql_5.x
#Feature: mysql 5.x v2 to db_manager upgrade tests
#  Tests the RightScale premium ServerTemplate
#
#  Scenario: Follow the steps in the v2 to db_manager upgrade guide. Then run the mysql checks.
# http://support.rightscale.com/03-Tutorials/02-AWS/02-Website_Edition/2.1_MySQL_Setup/MySQL_Setup_Migration%3a__EBS_to_EBS_Stripe
#
# PHASE 1) Launch a v2 master from a known hardcoded snapshot.
#  TODO - add the steps to create the v2 master from scratch.  The upgrade is the major
#         concern so lets get that done first.
#  Prerequisite: A Deployment with a running MySQL EBS Master-DB server 
#  (launched using a revision of the "MySQL EBS v2" ServerTemplate)
# Old school hand crafted deployment: https://my.rightscale.com/deployments/49925.  Make sure
# The one server is still up and running as master DB.
#
# Given A MySQL deployment
  @runner = VirtualMonkey::MysqlV2MigrationRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should set a variation lineage
  @runner.behavior(:set_variation_lineage)

# Then I should set a variation stripe count of "3"
  @runner.behavior(:set_variation_stripe_count, 3)

#
# PHASE 2) Launch a new v2
#
# Then I should launch all servers
  @runner.behavior(:launch_set, :s_one)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_set, :s_one, "operational")

# Then I should test promotion operations on the deployment
  @runner.behavior(:run_promotion_operations)

#
# PHASE 3) Initialize additional slave from db_manager snapshots
#
# Then I should launch all servers
  @runner.behavior(:launch_set, :s_two)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_set, :s_two, "operational")

# Then I should init a new db_manager slave
  @runner.behavior(:launch_db_manager_slave)

# Then I should test the new db_manager slave
  @runner.behavior(:run_checks)

  @runner.behavior(:run_logger_audit)
