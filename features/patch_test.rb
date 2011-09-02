set :runner, VirtualMonkey::Runner::Patch

hard_reset do
  @runner.stop_all
end

before do
  @runner.set_user_data("RS_patch_url=http://s3.amazonaws.com/rightscale_rightlink_dev")

  @runner.launch_all


  @runner.wait_for_all("operational")
end

test "default"
  @runner.run_patch_test
  @runner.reboot_all
  @runner.run_patch_test
  @runner.wait_for_all("operational")
end


