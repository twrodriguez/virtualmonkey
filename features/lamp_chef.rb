set :runner, VirtualMonkey::Runner::LampChef

hard_reset do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.wait_for_all("operational")
end

before "test_rax_backup" do
# Set the provider and account / auth information
  set_variation_storage_account_provider("rackspace")
end

test "default" do
  @runner.run_lamp_chef_checks
#  @runner.probe(".*", "su - mysql -s /bin/bash -c \"ulimit -n\"") { |r,st| r.to_i > 1024 }
  @runner.check_monitoring
#  @runner.run_logger_audit
end
