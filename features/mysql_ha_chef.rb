set :runner, VirtualMonkey::Runner::MysqlChefHA

`bin/monkey config set test_ordering strict`

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
end

before "smoke_test", "restore_and_become_master", "create_master_from_slave_backup","promote_slave_with_dead_master", "secondary_backup"  do
  #   create a block device
  #   add test tables into db
  #   write the backup
  # Now we have a backup that can be used to restore master and slave

  run_script("do_force_reset", s_one)
  run_script("do_force_reset", s_two)
  run_script("setup_privileges_admin", s_one)
  run_script("setup_privileges_admin", s_two)

  run_script("setup_block_device", s_one)
  run_script("do_tag_as_master", s_one)
  run_script("setup_replication_privileges", s_one)
  run_script('disable_backups',s_one)
  create_monkey_table(s_one)
  do_backup(s_one)
end

test "smoke_test"do
  create_table_replication(s_one ,"foo")
  do_init_slave(s_two)

  # check if the banana table is there
  # check for foo database
  check_table_bananas(s_two)
  check_table_replication(s_two, "foo")

  #      **** VERIFY PROMOTE ****
  do_promote_to_master(s_two)
  verify_master(s_two)
  create_table_replication(s_two ,"bar")
  check_table_replication(s_one, "bar")
  
  #   **** Verify Reboot **** 
  run_HA_reboot_operations
end

test "restore_and_become_master" do
  run_script("do_force_reset", s_one)

  # s_one is un-init
  do_restore_and_become_master(s_two)
  verify_master(s_two)
  do_init_slave(s_one)

  # verify master slave setup by a replication test
  create_table_replication(s_two ,"real_master")
  check_table_replication(s_one, "real_master")

  check_table_bananas(s_one)
  check_table_bananas(s_two)
end

test "create_master_from_slave_backup" do
  verify_master(s_one)
  do_init_slave(s_two)

  # write to slave file system so later we can verify if the backup came from a slave 
  write_to_slave("monkey_slave",s_two) 
  do_backup(s_two)
  run_script("do_force_reset", s_one)
  run_script("do_force_reset", s_two)

  do_restore_and_become_master(s_two)
  check_table_bananas(s_two)
  check_slave_backup(s_two, "monkey_slave") # looks for a file that was written to the slave
  verify_master(s_two)

  do_init_slave(s_one)
  # s_one is slave
  # s_two is master
  create_table_replication(s_two, "replication_works")
  check_table_replication(s_one, "replication_works")
end

test "promote_slave_with_dead_master" do
=begin
  verify_master(s_one)

  do_init_slave(s_two)
  run_script("do_force_reset", s_one) # kill the master

  do_promote_to_master(s_two)
  verify_master(s_two)
  do_init_slave(s_one)

  # verify master slave with replication
  create_table_replication(s_two, "dead_master")
  check_table_replication(s_one, "dead_master")

  check_table_bananas(s_one)
  check_table_bananas(s_two)
=end
end

#test "check_monitoring" do
 #  check_monitoring
 #  check_mysql_monitoring
#end

test "secondary_backup" do
  random_number = (rand(1000) % 2)
  if(random_number == 0)
    test_secondary_backup_ha("S3")
  else
    test_secondary_backup_ha("CloudFiles")
  end
end

after do
  @runner.release_dns
#  cleanup_volumes
#  cleanup_snapshots
end

#TODO checks for master vs slave backup setups
#  need to verify that the master servers backup cron job is using the master backup cron/minute/hour
#TODO enable and disable backups on both the master and slave servers -- this will be tested by hand -- inefficient by monkey
