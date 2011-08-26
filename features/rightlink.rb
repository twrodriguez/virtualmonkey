set :runner, VirtualMonkey::Runner::Rightlink

hard_reset do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.wait_for_all("operational")
  @runner.test_state_test_check
  @runner.test_remote_recipe_test
  @runner.test_remote_recipe_ping
  @runner.test_resource_remote_pong
  @runner.test_persist_test_check
  @runner.test_depend_check
  @runner.test_iteration_check
  @runner.test_print_inputs
end
