set :runner, VirtualMonkey::Runner::PhpChef

hard_reset do
  @runner.stop_all
end

before do
# PHP/FE variations

 # sets ssl inputs at deployment level

  @runner.setup_dns("dnsmadeeasy_new") # dnsmadeeasy
  @runner.set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
  @runner.set_variation_ssl
  @runner.set_variation_ssl_chain
  @runner.set_variation_ssl_passphrase

# Mysql variations
  @runner.set_variation_lineage
  @runner.set_variation_container

# launching
  @runner.launch_set(:mysql_servers)
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:mysql_servers, "operational")
  @runner.set_private_mysql_fqdn
  @runner.import_unified_app_sqldump
  @runner.wait_for_set(:fe_servers, "operational")
  @runner.launch_set(:app_servers)
  @runner.wait_for_all("operational")
  @runner.disable_fe_reconverge
#  @runner.disable_db_reconverge
  @runner.test_attach_all
end

#
## ATTACHMENT GROUP
#

test "attach_all" do
  @runner.test_attach_all
  @runner.frontend_checks(443)
end

test "attach_request" do
  @runner.test_attach_request
  @runner.frontend_checks(443)
  @runner.test_detach
end

after "attach_all", "attach_request" do
  @runner.test_detach
end

# Because we setup 2 frontends differently to test the code paths of "with:passphrase" and "without:passphrase", one frontend_checks run is sufficient to see if SSL is being served on all Fes
test "ssl" do
  @runner.test_attach_all
  @runner.frontend_checks(443)
  @runner.test_detach
end

#
## Cert Chain
#

test "ssl_chain" do
  @runner.test_ssl_chain
end

#
## Unified Application
#

test "reboot_operations" do
  @runner.run_reboot_operations
end

