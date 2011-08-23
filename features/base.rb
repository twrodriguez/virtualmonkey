set :runner, VirtualMonkey::Runner::Simple

clean_start do
  @runner.stop_all
end

before do
  @runner.tag_all_servers("rs_agent_dev:package=5.7.13")
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
