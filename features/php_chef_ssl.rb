set :runner, VirtualMonkey::Runner::PhpChef

clean_start do
  @runner.stop_all
end

#
## SSL GROUPING
#

before "ssl" do
  @runner.set_variation_ssl
  @runner.launch_all
  @runner.wait_for_all("operational")
  @runner.test_attach_all
end

test "ssl" do
  @runner.frontend_checks(443)
  @runner.test_detach
end
