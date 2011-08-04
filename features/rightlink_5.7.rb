set :runner, VirtualMonkey::Runner::Rightlink5_7

clean_start do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.wait_for_all("operational")
end


test "check_monitoring" do
  @runner.check_monitoring
end

test "run_all_operational_scripts" do

@runner.test_run_check_value
@runner.test_run_recipe_test_start
@runner.test_run_remote_recipe_ping
@runner.test_run_remote_pong
@runner.test_run_test_check
@runner.test_run_depend_check
@runner.test_iteration_output
end
