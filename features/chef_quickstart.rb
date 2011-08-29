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
end
