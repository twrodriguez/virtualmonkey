set :runner, VirtualMonkey::Runner::Shutdown

hard_reset do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.run_script!("shutdown", {'wait' => false})
# Then the server should become terminated
  @runner.wait_for_all("stopped")
end
