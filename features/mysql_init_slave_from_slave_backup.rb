@runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
@runner.behavior(:stop_all)
@runner.set_var(:set_variation_lineage)
@runner.set_var(:set_variation_stripe_count, 1)
@runner.set_var(:setup_dns, "virtualmonkey_shared_resources") # DNSMadeEasy
@runner.behavior(:launch_all)
@runner.behavior(:wait_for_all, "operational")
@runner.behavior(:init_slave_from_slave_backup)
@runner.behavior(:run_checks)
@runner.behavior(:check_monitoring)

# 
# PHASE 4) Terminate
#

@runner.behavior(:stop_all, true)
@runner.behavior(:release_dns)
