set :runner, VirtualMonkey::Runner::PhpChef

hard_reset do
  @runner.stop_all
end

#
## SSL GROUPING
#

before do
  @runner.set_master_db_dnsname
  @runner.set_variation_ssl
  @runner.set_variation_ssl_chain
  @runner.set_variation_ssl_passphrase
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:fe_servers, "operational")
  @runner.launch_set(:app_servers)
  @runner.wait_for_all("operational")
  @runner.test_attach_all
end

# Because we setup 2 frontends differently to test the code paths of "with:passphrase" and "without:passphrase", one frontend_checks run is sufficient to see if SSL is being served on all Fes
test "ssl" do
  @runner.frontend_checks(443)
  @runner.test_detach
end

#
## Cert Chain
#

test "ssl_chain" do
  @runner.test_ssl_chain
end
