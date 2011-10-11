set :runner, VirtualMonkey::Runner::Wishbone

hard_reset do
  @runner.stop_all
end

before do
# PHP/FE variations

  @runner.setup_dns("virtualmonkey_awsdns_new") # AWSDNS 
  @runner.set_variation_dnschoice("text:Route53") # set variation choice
  @runner.set_variation_http_only
#  @runner.tag_all_servers("rs_agent_dev:package=5.7.14")
# Mysql variations
  @runner.set_variation_lineage
  @runner.set_variation_container

# launching
  @runner.launch_set(:mysql_servers)
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:mysql_servers, "operational")
  @runner.set_private_mysql_fqdn
  @runner.import_unified_app_sqldump
  @runner.wait_for_set(:fe_servers, "operational")
  @runner.launch_set(:app_servers)
  @runner.wait_for_all("operational")
  @runner.disable_fe_reconverge
  @runner.setup_block_device
  sleep(120)
end

#
## Unified Application on 8000
#

before "run_unified_application_checks" do
  @runner.test_attach_all
end

test "run_unified_application_checks" do
  @runner.run_unified_application_checks(:fe_servers, 80)
end


test "check_monitoring" do
  @runner.check_monitoring
  @runner.check_monitoring_exec_apache_ps
  @runner.check_monitoring_exec_haproxy
end


test "attach_all" do
  @runner.test_attach_all
  @runner.frontend_checks(80)
end

test "attach_request" do
  @runner.test_attach_request
  @runner.frontend_checks(80)
end

after "attach_all", "attach_request", "run_unified_application_checks" do
  @runner.test_detach

end


test "reboot_operations" do
  @runner.run_reboot_operations
end

after do
  @runner.release_dns
end
