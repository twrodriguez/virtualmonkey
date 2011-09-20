set :runner, VirtualMonkey::Runner::MysqlChefHA

# s_one - the first server that is used to create a DB from scratch in order to get a valid
# backup for additional testing.
# s_two - the first real master  created from do_restore_and_become_master using the from scracth backup
# s_three - the first slave restored from a newly launched state.
#

#terminates servers if there are any running
hard_reset do
  stop_all
end

before do
  mysql_lookup_scripts
  set_variation_lineage
  set_variation_container
  setup_dns("dnsmadeeasy_new") # dnsmadeeasy
  set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
#  setup_dns("virtualmonkey_awsdns_new") # AWSDNS
#  set_variation_dnschoice("text:Route53") # set variation choice
  launch_all
  wait_for_all("operational")

  #setup_master_slave_block_devices( [ s_one, s_two ] ) #TODO fix this function
  disable_db_reconverge # it is important to disable this if we want
  disable_backups(s_one)
  disable_backups(s_two)
  disable_backups(s_three)
  #  TODO: fresh boot no need to force reset
#  do_force_reset(s_one)
  run_script("setup_block_device", s_one)
  create_monkey_table(s_one)
  run_script("do_backup", s_one)
  wait_for_snapshots
  # Now we have a backup that can be used to restore master and slave
  # This server is not a real master.  To create a real master the
  # restore_and_become_master recipe needs to be run on a new instance
  # This one should be re-launched before additional tests are run on it
end

#
# Force reset may hide some real world issues.
#TODO need on complete run that does not use force reset
test "sequential_test" do

#  do_force_reset(s_one)
#  remove_master_tags
#TODO both the first do_restore_and_become_master and slave_init must be run on newly launched systems.
  run_script("do_restore_and_become_master",s_two)

#TODO fix verify_master.  Also make sure it checks the DNS entries are updated.
#  verify_master(s_two) # run monkey check that compares the master timestamps

  #"backup_master"
  run_script("do_backup", s_two)
  wait_for_snapshots

  # "create_master_from_master_backup"
#TODO already done  do_force_reset(s_one)
#  remove_master_tags
#TODO the restore_and_become_master sets up the block device
#  run_script("setup_block_device", s_one)
#  run_script("do_restore_and_become_master",s_one)
  check_table_bananas(s_one)
  create_table_replication(s_one) # create a table in the  master that is not in slave for replication checks below

   #"create_slave_from_master_backup"
  run_script("do_init_slave", s_three)
  check_table_bananas(s_three) # also check if the banana table is there
  check_table_replication(s_three) # checks if the replication table exists in the slave

   #"backup_slave"
  #   TODO running this script should fail cause there already is a block_device on the server
#   run_script("setup_block_device", s_two)
   write_to_slave("the slave",s_three) # write to slave file system so later we can verify if the backup came from a slave
   run_script("do_backup", s_three)
   wait_for_snapshots

   #"create_master_from_slave_backup"
   cleanup_volumes  ## runs do_force_reset on both servers
   remove_master_tags
   run_script("do_restore_and_become_master",s_two)
   check_table_bananas(s_two)
   create_table_replication(s_two) # create a table in the  master that is not in slave for replication checks below
   check_slave_backup(s_two) # verify slave backup

   # We have one master (s_two) and a bad slave (from different master and disks wipted).
#TODO VERIFY that a slave can be restored from a slave backup
  run_script("do_init_slave", s_three)
  check_table_bananas(s_three) # also check if the banana table is there

   # "promote_slave_to_master"
  run_script("do_promote_to_master",s_three)
end


before 'reboot' do
  #run_script("setup_block_device", s_one)
end

test "reboot" do
#  check_mysql_monitoring
#  run_reboot_operations
#  check_monitoring
#  check_mysql_monitoring
end

after do
#  cleanup_volumes
#  cleanup_snapshots
end
test "tester" do
# verify_master(s_two)
#write_to_slave("the slave",s_two)
#check_slave_backup(s_two)
end
#test "default" do
#  run_chef_promotion_operations
#  run_chef_checks
#  check_monitoring
#  check_mysql_monitoring
#  run_HA_reboot_operations
#end


