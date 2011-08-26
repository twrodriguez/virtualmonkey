set :runner, VirtualMonkey::Runner::Simple

hard_reset do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.check_monitoring
  @runner.reboot_all
  @runner.wait_for_all("operational")
  @runner.check_monitoring
#  @runner.run_logger_audit
end
