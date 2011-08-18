set :runner, VirtualMonkey::Runner::Wishbone

clean_start do
@runner.stop_all
end


before do
# PHP/FE variations

# TODO: variations to set
# mysql fqdn
  @runner.setup_dns("dnsmadeeasy_new") # dnsmadeeasy
  @runner.set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
  @runner.set_variation_http_only
  @runner.tag_all_servers("rs_agent_dev:package=5.7.11")
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
#  @runner.disable_reconverge
end

#
## Unified Application on 8000
#

test "run_unified_application_checks" do
  sleep(120)
  @runner.run_unified_application_checks(:fe_servers, 80)

end


test "check_monitoring" do
  @runner.check_monitoring
end

=begin
#############################


# lb_haproxy::do_attach_all #
#############################

before "script_1" do
end

test "script_1" do
  run_script_on_set("script_1", server_templates.detect { |st| st.name =~ /Load Balancer (Chef) - Alpha/ }, true, {})
end

after "script_1" do
end

#############################
# lb_haproxy::handle_attach #
#############################

before "script_2" do
end

test "script_2" do
  run_script_on_set("script_2", server_templates.detect { |st| st.name =~ /Load Balancer (Chef) - Alpha/ }, true, {})
end

after "script_2" do
end

#############################
# lb_haproxy::handle_detach #
#############################

before "script_3" do
end

test "script_3" do
  run_script_on_set("script_3", server_templates.detect { |st| st.name =~ /Load Balancer (Chef) - Alpha/ }, true, {})
end

after "script_3" do
end

############################
# sys_firewall::setup_rule #
############################

before "script_4" do
end

test "script_4" do
  run_script_on_set("script_4", server_templates.detect { |st| st.name =~ /Load Balancer (Chef) - Alpha/ }, true, {})
end

after "script_4" do
end

##################################
# sys::do_reconverge_list_enable #
##################################

before "script_5" do
end

test "script_5" do
  run_script_on_set("script_5", server_templates.detect { |st| st.name =~ /Load Balancer (Chef) - Alpha/ }, true, {})
end

after "script_5" do
end

###################################
# sys::do_reconverge_list_disable #
###################################

before "script_6" do
end

test "script_6" do
  run_script_on_set("script_6", server_templates.detect { |st| st.name =~ /Load Balancer (Chef) - Alpha/ }, true, {})
end

after "script_6" do
end

###########################
# app_php::do_update_code #
###########################

before "script_7" do
end

test "script_7" do
  run_script_on_set("script_7", server_templates.detect { |st| st.name =~ /PHP App Server (Chef) - Alpha/ }, true, {})
end

after "script_7" do
end

#################################
# lb_haproxy::do_attach_request #
#################################

before "script_8" do
end

test "script_8" do
  run_script_on_set("script_8", server_templates.detect { |st| st.name =~ /PHP App Server (Chef) - Alpha/ }, true, {})
end

after "script_8" do
end

#################################
# lb_haproxy::do_detach_request #
#################################

before "script_9" do
end

test "script_9" do
  run_script_on_set("script_9", server_templates.detect { |st| st.name =~ /PHP App Server (Chef) - Alpha/ }, true, {})
end

after "script_9" do
end

############################
# sys_firewall::setup_rule #
############################

before "script_10" do
end

test "script_10" do
  run_script_on_set("script_10", server_templates.detect { |st| st.name =~ /PHP App Server (Chef) - Alpha/ }, true, {})
end

after "script_10" do
end

###############################
# sys_firewall::do_list_rules #
###############################

before "script_11" do
end

test "script_11" do
  run_script_on_set("script_11", server_templates.detect { |st| st.name =~ /PHP App Server (Chef) - Alpha/ }, true, {})
end

after "script_11" do
end

##################################
# sys::do_reconverge_list_enable #
##################################

before "script_12" do
end

test "script_12" do
  run_script_on_set("script_12", server_templates.detect { |st| st.name =~ /PHP App Server (Chef) - Alpha/ }, true, {})
end

after "script_12" do
end

###################################
# sys::do_reconverge_list_disable #
###################################

before "script_13" do
end

test "script_13" do
  run_script_on_set("script_13", server_templates.detect { |st| st.name =~ /PHP App Server (Chef) - Alpha/ }, true, {})
end

after "script_13" do
end

################################
# db_mysql::setup_block_device #
################################

before "script_14" do
end

test "script_14" do
  run_script_on_set("script_14", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_14" do
end

#######################
# db_mysql::do_backup #
#######################

before "script_15" do
end

test "script_15" do
  run_script_on_set("script_15", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_15" do
end

###################################
# db_mysql::do_backup_cloud_files #
###################################

before "script_16" do
end

test "script_16" do
  run_script_on_set("script_16", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_16" do
end

##########################
# db_mysql::do_backup_s3 #
##########################

before "script_17" do
end

test "script_17" do
  run_script_on_set("script_17", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_17" do
end

###########################
# db_mysql::do_backup_ebs #
###########################

before "script_18" do
end

test "script_18" do
  run_script_on_set("script_18", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_18" do
end

########################
# db_mysql::do_restore #
########################

before "script_19" do
end

test "script_19" do
  run_script_on_set("script_19", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_19" do
end

####################################
# db_mysql::do_restore_cloud_files #
####################################

before "script_20" do
end

test "script_20" do
  run_script_on_set("script_20", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_20" do
end

###########################
# db_mysql::do_restore_s3 #
###########################

before "script_21" do
end

test "script_21" do
  run_script_on_set("script_21", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_21" do
end

############################
# db_mysql::do_restore_ebs #
############################

before "script_22" do
end

test "script_22" do
  run_script_on_set("script_22", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_22" do
end

##################################################
# db_mysql::setup_continuous_backups_cloud_files #
##################################################

before "script_23" do
end

test "script_23" do
  run_script_on_set("script_23", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_23" do
end

#########################################
# db_mysql::setup_continuous_backups_s3 #
#########################################

before "script_24" do
end

test "script_24" do
  run_script_on_set("script_24", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_24" do
end

##########################################
# db_mysql::setup_continuous_backups_ebs #
##########################################

before "script_25" do
end

test "script_25" do
  run_script_on_set("script_25", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_25" do
end

#######################################################
# db_mysql::do_disable_continuous_backups_cloud_files #
#######################################################

before "script_26" do
end

test "script_26" do
  run_script_on_set("script_26", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_26" do
end

##############################################
# db_mysql::do_disable_continuous_backups_s3 #
##############################################

before "script_27" do
end

test "script_27" do
  run_script_on_set("script_27", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_27" do
end

###############################################
# db_mysql::do_disable_continuous_backups_ebs #
###############################################

before "script_28" do
end

test "script_28" do
  run_script_on_set("script_28", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_28" do
end

############################
# db_mysql::do_force_reset #
############################

before "script_29" do
end

test "script_29" do
  run_script_on_set("script_29", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_29" do
end

###########################
# db::do_appservers_allow #
###########################

before "script_30" do
end

test "script_30" do
  run_script_on_set("script_30", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_30" do
end

##########################
# db::do_appservers_deny #
##########################

before "script_31" do
end

test "script_31" do
  run_script_on_set("script_31", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_31" do
end

############################
# sys_firewall::setup_rule #
############################

before "script_32" do
end

test "script_32" do
  run_script_on_set("script_32", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_32" do
end

###############################
# sys_firewall::do_list_rules #
###############################

before "script_33" do
end

test "script_33" do
  run_script_on_set("script_33", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_33" do
end

##################################
# sys::do_reconverge_list_enable #
##################################

before "script_34" do
end

test "script_34" do
  run_script_on_set("script_34", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_34" do
end

###################################
# sys::do_reconverge_list_disable #
###################################

before "script_35" do
end

test "script_35" do
  run_script_on_set("script_35", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_35" do
end

###########################
# sys_dns::do_set_private #
###########################

before "script_36" do
end

test "script_36" do
  run_script_on_set("script_36", server_templates.detect { |st| st.name =~ /Database Manager for MySQL 5.1 (Chef) - Alpha/ }, true, {})
end

after "script_36" do
end

after do
  # Cleanup

end
=end

