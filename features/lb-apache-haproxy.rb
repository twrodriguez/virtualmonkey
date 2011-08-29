set :runner, VirtualMonkey::Runner::FeApp

hard_reset do
  @runner.stop_all
end

before do
  @runner.set_master_db_dnsname
end

test "default" do
  @runner.launch_set("Load Balancer")
  @runner.wait_for_set("Load Balancer", "operational")
  @runner.set_lb_hostname
  @runner.launch_set("App Server")
  @runner.wait_for_set("App Server", "operational")
  @runner.run_unified_application_checks(:app_servers)
  @runner.frontend_checks
  @runner.log_rotation_checks
  @runner.run_reboot_operations
#  @runner.run_logger_audit
end
