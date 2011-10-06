set :runner, VirtualMonkey::Runner::PhpChef

hard_reset do
  @runner.stop_all
end

before do
# PHP/FE variations

  @runner.setup_dns("virtualmonkey_awsdns_new") # AWSDNS 
  @runner.set_variation_dnschoice("text:Route53") # set variation choice
  @runner.set_variation_http_only

# Mysql variations
  @runner.set_variation_lineage
  @runner.set_variation_container

  @runner.launch_set(:mysql_servers)
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:mysql_servers, "operational")
  @runner.set_private_mysql_fqdn
  @runner.import_unified_app_sqldump
  @runner.wait_for_set(:fe_servers, "operational")
  @runner.launch_set(:app_servers)
  @runner.wait_for_all("operational")
  @runner.disable_fe_reconverge
end

#
## Unified Application on 8000
#

test "run_unified_application_checks" do
sleep(120)
  @runner.run_unified_application_checks(:fe_servers, 80)
end

after do
  @runner.release_dns
end
