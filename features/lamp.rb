set :runner, VirtualMonkey::Runner::Lamp

hard_reset do
  @runner.stop_all
end

before do
# Set the provider and account / auth information
  set_variation_storage_account_provider
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.run_lamp_checks
#  @runner.run_mysqlslap_check
  @runner.probe(".*", "su - mysql -s /bin/bash -c \"ulimit -n\"") { |r,st| r.to_i > 1024 }
  @runner.check_monitoring
#  @runner.run_logger_audit
end
