set :runner, VirtualMonkey::Runner::DrToolbox

hard_reset do
  stop_all
end

before do
#  tag_all_servers("rs_agent_dev:package=5.7.14")
  set_variation_lineage
  set_variation_container
  set_variation_mount_point
  launch_all
  wait_for_all("operational")
end

#
# Backup, Restore, Restore + Timestamp Override
#

before "volume_backup", "s3_backup", "cloudfiles_backup" do
  run_script("do_force_reset", s_one)
end

test "volume_backup" do
  test_backup
end

test "s3_backup" do
  test_backup("S3")
end

test "cloudfiles_backup" do
  test_backup("CloudFiles")
end

after "volume_backup", "s3_backup", "cloudfiles_backup" do
  run_script("do_force_reset", s_one)
end

#
# Continuous Backups
#

before "continuous_volume_backup", "continuous_s3_backup", "continuous_cloudfiles_backup" do
  run_script("do_force_reset", s_one)
end

test "continuous_volume_backup" do
  test_continuous_backups
end

test "continuous_s3_backup" do
  test_continuous_backups("S3")
end

test "continuous_cloudfiles_backup" do
  test_continuous_backups("CloudFiles")
end

after "continuous_volume_backup", "continuous_s3_backup", "continuous_cloudfiles_backup" do
  run_script("do_force_reset", s_one)
end

#
# Mount Point
#

before 'mount_point' do
  set_variation_mount_point('/mnt/monkey_test')
end

test 'mount_point' do
  transaction do
    test_backup
  end
end

after 'mount_point' do
  cleanup_volumes
  cleanup_snapshots
  set_variation_mount_point
end

test "monitoring_checks" do
  check_monitoring
end

after do
  cleanup_volumes
  cleanup_snapshots
end
