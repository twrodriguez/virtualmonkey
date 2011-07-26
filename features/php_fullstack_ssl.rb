set :runner, VirtualMonkey::Runner::PhpChef

clean_start do
  @runner.stop_all
end

before do
# PHP/FE variations

# TODO: variations to set
# mysql fqdn

 # sets ssl inputs at deployment level
  @runner.set_variation_ssl
  @runner.set_variation_ssl_chain
  @runner.set_variation_ssl_passphrase

# Mysql variations
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.set_variation_storage_type

# launching
  @runner.launch_set(:mysql_servers)
  @runner.launch_set(:fe_servers)
  @runner.wait_for_set(:mysql_servers, "operational")
  @runner.set_private_mysql_fqdn
  @runner.import_unified_app_sqldump
  @runner.wait_for_set(:fe_servers, "operational")
  @runner.launch_set(:app_servers)
  @runner.wait_for_all("operational")
  @runner.disable_reconverge
  @runner.test_attach_all
end

#
## Unified Application
#

#test "run_unified_application_checks" do
# @runner.run_unified_application_checks(:app_servers, 80)
#end

test "reboot_operations" do
  @runner.run_reboot_operations
end

# These tests are covered in the php_full_stack.rb feature
#test "monitoring" do
#  @runner.check_monitoring
#end

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
# These tests are covered in the php_full_stack.rb feature
#test "base_checks" do
#  @runner.check_monitoring
#  @runner.run_reboot_operations
#  @runner.wait_for_all("operational")
#  @runner.check_monitoring
##  @runner.run_logger_audit
#end


#
## Reconverge Test
#

# These tests are covered in the php_full_stack.rb feature
#before "reconverge" do
#  @runner.enable_reconverge
#  @runner.set_variation_cron_time
#end
#
#test "reconverge" do
#  @runner.detach_all
#  puts sleep(60*2) # 2 minutes
#  @runner.frontend_checks(80)
#end
#  
#before "cron_reconverge" do
#  @runner.enable_reconverge
#end
#  
#test "cron_reconverge" do
#  @runner.test_cron_reconverge
#end
  
#after "reconverge", "cron_reconverge" do
#  @runner.disable_reconverge
#end

