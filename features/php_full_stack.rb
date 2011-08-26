set :runner, VirtualMonkey::Runner::PhpChef

hard_reset do
  @runner.stop_all
end

before do
# PHP/FE variations

# TODO: variations to set
# mysql fqdn
 @runner.setup_dns("dnsmadeeasy_new") # dnsmadeeasy
@runner.set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
  @runner.set_variation_http_only

# Mysql variations
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.set_variation_storage_type

# launching
  @runner.launch_set(:mysql_servers)
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:mysql_servers, "operational")
  #@runner.set_private_mysql_fqdn
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

#test "reboot_operations" do
 # @runner.run_reboot_operations
#end

#test "monitoring" do
#  @runner.check_monitoring
#end

#
## ATTACHMENT GROUP
#

#test "attach_all" do
#  @runner.test_attach_all
#  @runner.frontend_checks(80)
#end

#test "attach_request" do
#  @runner.test_attach_request
#  @runner.frontend_checks(80)
#end

#after "attach_all", "attach_request" do
#  @runner.test_detach
#end

#
## Reconverge Test
#

#before "reconverge" do
 # @runner.enable_reconverge
 # @runner.set_variation_cron_time
#end

#test "reconverge" do
#  @runner.detach_all
#  puts sleep(60*2) # 2 minutes
#  @runner.frontend_checks(80)
#end

#before "cron_reconverge" do
#  @runner.enable_reconverge
#end

#test "cron_reconverge" do
 # @runner.test_cron_reconverge    ###### not doing this anymore so dont test it
#end

#after "reconverge", "cron_reconverge" do
 # @runner.disable_reconverge
#end

#
## Defunct Server Test
#

#before "defunct_server" do
#  @runner.set_variation_defunct_server
#end

#test "defunct_server" do
#  @runner.transaction do
#    @runner.test_attach_all
#    @runner.test_defunct_server
#  end
#end
