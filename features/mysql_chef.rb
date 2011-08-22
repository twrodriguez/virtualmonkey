set :runner, VirtualMonkey::Runner::MysqlChef

clean_start do
  @runner.stop_all
end

before do
  @runner.tag_all_servers("rs_agent_dev:package=5.7.13")
  @runner.setup_dns("virtualmonkey_awsdns_new") # AWSDNS 
  @runner.set_variation_dnschoice("text:Route53") # set variation choice
  @runner.set_variation_http_only
  
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.set_variation_storage_type
  
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.setup_block_device
  @runner.do_backup
  @runner.do_force_reset
  @runner.do_restore
#  @runner.test_multicloud
  @runner.check_monitoring
  @runner.check_mysql_monitoring
  @runner.run_reboot_operations
  @runner.check_monitoring
  @runner.run_restore_with_timestamp_override
  @runner.run_logger_audit
  @runner.stop_all(true)
  @runner.release_dns
end
