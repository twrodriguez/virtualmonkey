set :runner, VirtualMonkey::Runner::MysqlChef

hard_reset do
  @runner.stop_all
end

before do
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.launch_all
  @runner.wait_for_all("operational")
  @runner.disable_db_reconverge
end

test "test_primary_backup" do
  @runner.test_primary_backup
end

after 'test_primary_backup' do
  @runner.do_force_reset
end

test "test_secondary_backup_s3" do
  @runner.test_secondary_backup("S3")
end

after 'test_secondary_backup_s3' do
  @runner.do_force_reset
end
 
test "test_secondary_backup_cloudfiles" do
  @runner.test_secondary_backup("CloudFiles")
end

test "reboot" do
  @runner.check_mysql_monitoring
  @runner.run_reboot_operations
  @runner.check_monitoring
  @runner.check_mysql_monitoring
  @runner.run_restore_with_timestamp_override
end

# TODO: cleanup snapshots, primary and secondary containers