set :runner, VirtualMonkey::Runner::MysqlChefHA
master_server = s_one
slave_server  = s_two
#terminates servers if there are any running
hard_reset do
#  stop_all
end

before do
  mysql_lookup_scripts
  set_variation_lineage
  set_variation_container
#  setup_dns("dnsmadeeasy_new") # dnsmadeeasy
#  set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
  launch_all
  wait_for_all("operational")
  disable_db_reconverge # it is important to disable this if we want
  #setup_master_slave_block_devices( [ s_one, s_two ] ) #TODO fix this function
end

test "create_master_from_scratch" do
  make_master(s_one)
  create_monkey_table(s_one)
  check_master(s_one)
end

test "backup_master" do
  run_script("do_backup", s_one)
  wait_for_snapshots
end

test "create_master_from_master_backup" do
  cleanup_volumes  ## runs do_force_reset on both servers
  remove_master_tags
  run_script("do_restore_and_become_master",s_one)
  check_table(s_one)
  create_table_replication(s_one) # create a table in the  master that is not in slave for replication checks below
end

test "create_slave_from_master_backup" do
  run_script("do_init_slave", s_two)
  check_table_bananas(s_two) # also check if the banana table is there
  check_table_replication(s_two) # checks if the replication table exists in the slave
end

test "backup_slave" do
  run_script("do_backup", s_two)
  wait_for_snapshots
end

test "create_master_from_slave_backup" do
  cleanup_volumes  ## runs do_force_reset on both servers
  remove_master_tags
  run_script("do_restore_and_become_master",s_one)
  check_table(s_one)
#TODO how do we verify this is a slave backup?
end

test "promote_slave_to_master" do
# this requires dns items to be uncommented at before do stuff
#  run_script("do_promote_to_master",s_one)
end


before 'reboot' do
  run_script("setup_block_device", s_one)
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
write_to_slave("the slave",s_two)
check_slave_backup(s_two)
end
#test "default" do
#  run_chef_promotion_operations
#  run_chef_checks
#  check_monitoring
#  check_mysql_monitoring
#  run_HA_reboot_operations
#end


