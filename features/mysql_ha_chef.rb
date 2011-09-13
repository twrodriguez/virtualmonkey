set :runner, VirtualMonkey::Runner::MysqlHAChef

hard_reset do
  stop_all
end

before do
  set_variation_lineage
  set_variation_container
  setup_dns("dnsmadeeasy_new") # dnsmadeeasy
  set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
  launch_all
  wait_for_all("operational")
  disable_db_reconverge
end

test "create_master_from_scratch" do
  find_master
  create_monkey_table
end

test "backup_master" do
  find_master
end

test "create_master_from_master_backup" do
end

test "create_slave_from_master_backup" do
end

test "backup_slave" do
end

test "create_master_from_slave_backup" do
end

before 'reboot' do
  do_force_reset
  run_script("setup_block_device", s_one)
end

test "reboot" do
  check_mysql_monitoring
  run_reboot_operations
  check_monitoring
  check_mysql_monitoring
end

after do
  cleanup_volumes
  cleanup_snapshots
end

#test "default" do
#  run_chef_promotion_operations
#  run_chef_checks
#  check_monitoring
#  check_mysql_monitoring
#  run_HA_reboot_operations
#end

