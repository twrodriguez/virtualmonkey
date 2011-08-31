set :runner, VirtualMonkey::Runner::MysqlChef

hard_reset do
  stop_all
end

before do
  set_variation_lineage
  set_variation_container
  launch_all
  wait_for_all("operational")
  disable_db_reconverge
end

test "primary_backup" do
  test_primary_backup
end

test "secondary_backup_s3" do
  test_secondary_backup("S3")
end

test "test_secondary_backup_cloudfiles" do
  test_secondary_backup("CloudFiles")
end

after 'primary_backup', 'secondary_backup_s3', 'secondary_backup_cloudfiles', 'reboot' do
  do_force_reset
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
