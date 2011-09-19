set :runner, VirtualMonkey::Runner::MysqlChefHA

#terminates servers if there are any running
hard_reset do
#  stop_all
end

before do
  mysql_lookup_scripts
  set_variation_lineage
  set_variation_container
   setup_dns("virtualmonkey_awsdns_new") # AWSDNS
   set_variation_dnschoice("text:Route53") # set variation choice
  launch_all
  wait_for_all("operational")

  #setup_master_slave_block_devices( [ s_one, s_two ] ) #TODO fix this function
  disable_db_reconverge # it is important to disable this if we want
  disable_backups(s_one)
  disable_backups(s_two)
  do_force_reset(s_one)
  run_script("setup_block_device", s_one)
end

test "sequential_test" do

  create_monkey_table(s_one)
  run_script("do_backup", s_one)
  wait_for_snapshots
  do_force_reset(s_one)

  run_script("do_restore_and_become_master",s_one)

  #create_master_from_scratch"
  #make_master(s_one)
  check_master(s_one) # run script to check master
  verify_master(s_one) # run monkey check that compares the master timestamps

  #"backup_master"
  run_script("do_backup", s_one)
  wait_for_snapshots

  # "create_master_from_master_backup"
  cleanup_volumes  ## runs do_force_reset on both servers
  remove_master_tags
  run_script("setup_block_device", s_one)
  run_script("do_restore_and_become_master",s_one)
  check_table_bananas(s_one)
  create_table_replication(s_one) # create a table in the  master that is not in slave for replication checks below

   #"create_slave_from_master_backup"
  run_script("do_init_slave", s_two)
  check_table_bananas(s_two) # also check if the banana table is there
  check_table_replication(s_two) # checks if the replication table exists in the slave

   #"backup_slave"
   run_script("setup_block_device", s_two)
   write_to_slave("the slave",s_two) # write to slave file system so later we can verify if the backup came from a slave
   run_script("do_backup", s_two)
   wait_for_snapshots

   #"create_master_from_slave_backup"
   cleanup_volumes  ## runs do_force_reset on both servers
   remove_master_tags
   run_script("do_restore_and_become_master",s_one)
   check_table_bananas(s_one)
   create_table_replication(s_one) # create a table in the  master that is not in slave for replication checks below
   check_slave_backup(s_one) # verify slave backup

   # "promote_slave_to_master"
# this requires dns items to be uncommented at before do stuff
#  run_script("do_promote_to_master",s_one)
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


