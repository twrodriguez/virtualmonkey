  @runner = VirtualMonkey::PhpChefRunner.new(ENV['DEPLOYMENT'])
  @runner.behavior(:stop_all)
  @runner.set_var(:set_master_db_dnsname)
  @runner.behavior(:launch_all)
  @runner.behavior(:wait_for_all, "operational")
  @runner.behavior(:test_attach_all)
  @runner.behavior(:run_unified_application_checks, :app_servers)
  @runner.behavior(:frontend_checks)
#  @runner.behavior(:log_rotation_checks)
#  @runner.behavior(:setup_https_vhost)
  @runner.behavior(:run_reboot_operations)
  @runner.behavior(:check_monitoring)
#  @runner.behavior(:run_logger_audit)

  @runner.behavior(:test_detach)
# detach needs to remove the tags
# attach_all needs to refresh the list (not just add all)


