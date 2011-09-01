set :runner, VirtualMonkey::Runner::PhpChef

hard_reset do
  @runner.stop_all
end

before do
  @runner.set_master_db_dnsname
  @runner.set_variation_http_only
  @runner.set_variation_cron_time
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:fe_servers, "operational")
  @runner.launch_set(:app_servers)
  @runner.wait_for_all("operational")
  @runner.disable_reconverge
end

#
## Unified Application on 8000
#

test "run_unified_application_checks" do
  @runner.run_unified_application_checks(:app_servers, 8000)
end

test "reboot_operations" do
  @runner.run_reboot_operations
end

test "monitoring" do
  @runner.check_monitoring
end

#
## ATTACHMENT GROUP
#

test "attach_all" do
  @runner.test_attach_all
  @runner.frontend_checks(80)
end

test "attach_request" do
  @runner.test_attach_request
  @runner.frontend_checks(80)
end

after "attach_all", "attach_request" do
  @runner.test_detach
end

#
## Reconverge Test
#

before "reconverge" do
  @runner.enable_reconverge
end

test "reconverge" do
  @runner.detach_all
  puts sleep(130)
  @runner.frontend_checks(80)
end

after "reconverge" do
  @runner.disable_reconverge
end
