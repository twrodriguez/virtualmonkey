set :runner, VirtualMonkey::Runner::PhpChef

hard_reset do
  @runner.stop_all
end

before do
# PHP/FE variations

# TODO: variations to set
# mysql fqdn
  @runner.setup_dns("virtualmonkey_dyndns_new") # AWSDNS 
  @runner.set_variation_dnschoice("text:DynDNS") # set variation choice
  @runner.set_variation_http_only

# Mysql variations
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.set_variation_storage_type

# launching
  @runner.launch_set(:mysql_servers)
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:mysql_servers, "operational")
 # @runner.set_private_mysql_fqdn
 @runner.import_unified_app_sqldump
  @runner.wait_for_set(:fe_servers, "operational")
  @runner.launch_set(:app_servers)
  @runner.wait_for_all("operational")
  @runner.disable_reconverge
end

#
## Unified Application on 8000
#

test "run_unified_application_checks" do
sleep(360)
  @runner.run_unified_application_checks(:fe_servers, 80)

end

