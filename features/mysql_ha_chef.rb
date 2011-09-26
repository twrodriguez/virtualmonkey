set :runner, VirtualMonkey::Runner::MysqlChefHA

# s_one - the first server that is used to create a DB from scratch in order to get a valid
# backup for additional testing.
# s_two - the first real master  created from do_restore_and_become_master using the from
# scracth backup
# s_three - the first slave restored from a newly launched state.
#

# Terminates servers if there are any running
hard_reset do
  stop_all
end

before do
   mysql_lookup_scripts
   set_variation_lineage
   set_variation_container
   setup_dns("dnsmadeeasy_new") # dnsmadeeasy
   set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
   launch_all
   wait_for_all("operational")

   disable_db_reconverge # it is important to disable this if we want to verify what backup we are restoring from
   disable_all_backups

   run_script("setup_block_device", s_one)
   create_monkey_table(s_one)
   run_script("do_backup", s_one)
   wait_for_snapshots
 
   #terminate s_one - it is no longer needed - access should error after this point
   # Now we have a backup that can be used to restore master and slave
   # This server is not a real master.  To create a real master the
   # restore_and_become_master recipe needs to be run on a new instance
   # This one should be re-launched before additional tests are run on it
   transaction { s_one.relaunch }
end

test "sequential_test" do

   run_script("do_restore_and_become_master",s_two)

   # run monkey check that compares the master timestamps
   # verify_master tags  checks the DNS entries are updated.
   verify_master(s_two) # run monkey check that compares the master timestamps
   # "create_master_from_master_backup"
   check_table_bananas(s_two)

   #"backup_master"
   run_script("do_backup", s_two)
   wait_for_snapshots
   create_table_replication(s_two) # create a table in the  master that is not in slave for replication checks below

   #"create_slave_from_master_backup"
   run_script("do_init_slave", s_three)
   check_table_bananas(s_three) # also check if the banana table is there
   check_table_replication(s_three) # checks if the replication table exists in the slave

   # After this point we can use force reset.  We hav verified the create master and slave init
   # on fresh servers
   #"backup_slave"
   write_to_slave("the slave",s_three) # write to slave file system so later we can verify if the backup came from a slave
   run_script("do_backup", s_three)
   wait_for_snapshots

   #TODO remove master tags should also hose the DNS settings.  change the ip to 1.1.1.1
   #"create_master_from_slave_backup"
   cleanup_volumes  ## runs do_force_reset on ALL servers
   remove_master_tags
   run_script("do_restore_and_become_master",s_two)
   check_table_bananas(s_two)
   check_table_replication(s_two) # create a table in the  master that is not in slave for replication checks below
   check_slave_backup(s_two) # looks for a file that was written to the slave

   # We have one master (s_two) and a bad slave (from different master and disks wipted).
   #TODO VERIFY that a slave can be restored from a slave backup
   run_script("do_force_reset", s_three)
   run_script("do_init_slave", s_three)
   check_table_bananas(s_three) # also check if the banana table is there
   check_table_replication(s_three) # also check if the replication table is there

   # "promote_slave_to_master"
   # run_script("do_promote_to_master",s_three)
   run_HA_reboot_operations
   check_table_bananas(s_three) # also check if the banana table is there
   check_table_replication(s_three) # also check if the replication table is there
   check_table_bananas(s_two)
   check_table_replication(s_two) # create a table in the  master that is not in slave for replication checks below
   check_slave_backup(s_two) # looks for a file that was written to the slave
   #TODO do this one more time i.e. promote the oldmaster/new slave back to a master
   #  this will vefify that there are no files etc.. that break promotion
end

#TODO promote a slave server with a dead master
#  recreate a master slave setup (or use current?)
#  backup the master
#  terminate the master
#  promote the slave


#TODO reboot needs to:
#  reboot a slave, verify that it is operational, then add a table to master and verity replication
#  reboot the master, verify opernational - " " ^
before 'reboot' do
  #run_script("setup_block_device", s_one)
end

#TODO checks for master vs slave backup setups
#  need to verify that the master servers backup cron job is using the master backup cron/minute/hour
#TODO enable and disable backups on both the master and slave servers
#TODO monitoring checks
#TODO check for reported issues i.e. tickets

test "reboot" do
#run_script("do_restore_and_become_master",s_two)
#remove_master_tags
#print "hello\n"
#print  get_input_from_server(s_one, "db/fqdn")

#verify_master(s_two)
#remove_master_tags
#  check_mysql_monitoring
#  run_reboot_operations
#  check_monitoring
#  check_mysql_monitoring
end

after do
#  cleanup_volumes
#  cleanup_snapshots
end
