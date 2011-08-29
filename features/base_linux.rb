set :runner, VirtualMonkey::Runner::SimpleLinux

hard_reset do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.servers.first.wait_for_state("operational",1200)
end

test "default" do
# @runner.check_monitoring
# @runner.set_variation_swap_size("2.0") # string  x GB of swap size
#  @runner.test_run_swap_space ## test to see if the swap space works
  @runner.reboot_all
  @runner.servers.first.wait_for_state("operational",1200)
  #@runner.check_monitoring
  #@runner.run_logger_audit


 # @runner.test_run_swap_space ## test to see if the swap space works
  sleep(60) ## sleep for 60 seconds so setup can run
  @runner.test_swapspace ## check if swapspace was created correctly
end

#test "swapspace" do
 # @runner.test_swapspace ## check if swapspace was created correctly
#end
