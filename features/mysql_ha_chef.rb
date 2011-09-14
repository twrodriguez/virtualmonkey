set :runner, VirtualMonkey::Runner::MysqlChefHA

#terminates servers if there are any running
hard_reset do
  #stop_all
end

before do
  mysql_lookup_scripts
#  set_variation_lineage
#  set_variation_container
#  setup_dns("dnsmadeeasy_new") # dnsmadeeasy
#  set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
#  launch_all
#  wait_for_all("operational")
#  disable_db_reconverge
end

test "create_master_from_scratch" do
  make_master(s_one)
  create_monkey_table(s_one)
  check_master(s_one)
end

test "backup_master" do
  run_script("setup_block_device", s_one)
  probe(s_one, "touch /mnt/storage/monkey_was_here")
  run_script("do_backup", s_one)
  wait_for_snapshots
  run_script("do_force_reset", s_one)
  run_script("do_restore", s_one)
  probe(s_one, "ls /mnt/storage") do |result, status|
    raise "FATAL: no files found in the backup" if result == nil || result.empty?
    true
  end
  run_script("do_force_reset", s_one)
  run_script("do_restore", s_one, {"db/backup/timestamp_override" =>
                                   "text:#{find_snapshot_timestamp(s_one)}" })
  probe(s_one, "ls /mnt/storage") do |result, status|
    raise "FATAL: no files found in the backup" if result == nil || result.empty?
    true
  end
end

test "create_master_from_master_backup" do
  #do_restore_and_become_master
end

test "create_slave_from_master_backup" do
end

test "backup_slave" do
end

test "create_master_from_slave_backup" do
end

test "promote_to_master" do
end


before 'reboot' do
  do_force_reset
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

#test "default" do
#  run_chef_promotion_operations
#  run_chef_checks
#  check_monitoring
#  check_mysql_monitoring
#  run_HA_reboot_operations
#end

