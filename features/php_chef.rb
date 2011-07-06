set :runner, VirtualMonkey::Runner::PhpChef

clean_start do
  @runner.stop_all
end

before do
  @runner.set_master_db_dnsname
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.test_attach_all
  @runner.run_unified_application_checks(:app_servers)
  @runner.frontend_checks
  @runner.run_reboot_operations
  @runner.check_monitoring

  @runner.test_detach
end

test "chef2" do
  @runner.test_attach_request
  @runner.run_unified_application_checks(:app_servers)
  @runner.frontend_checks
  @runner.run_reboot_operations
  @runner.check_monitoring
end

before "ssl" do
  @runner.set_variation_ssl
end

test "ssl" do
  @runner.test_attach_all
  @runner.run_unified_application_checks(:app_servers)
  @runner.frontend_checks
  @runner.run_reboot_operations
  @runner.check_monitoring

  @runner.test_detach
end
