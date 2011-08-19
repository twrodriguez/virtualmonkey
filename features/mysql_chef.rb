set :runner, VirtualMonkey::Runner::MysqlChef

clean_start do
  @runner.stop_all
end

before do
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.set_variation_storage_type("volume")
#  @runner.setup_dns("virtualmonkey_shared_resources") # DNSMadeEasy
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.test_ebs
#  @runner.setup_block_device
#  @runner.import_unified_app_sqldump
#sleep 20*60
#  @runner.do_backup
#sleep 20*60
#  @runner.do_force_reset
#sleep 20*60
#  @runner.do_restore
#  @runner.test_multicloud
#  @runner.check_monitoring
#  @runner.check_mysql_monitoring
#  @runner.run_reboot_operations
#  @runner.check_monitoring
#  @runner.run_restore_with_timestamp_override
#  @runner.run_logger_audit
#  @runner.stop_all(true)
#  @runner.release_dns
end
