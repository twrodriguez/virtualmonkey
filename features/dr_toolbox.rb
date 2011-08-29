set :runner, VirtualMonkey::Runner::DrToolbox

hard_reset do
  @runner.stop_all
end

before do
#  @runner.tag_all_servers("rs_agent_dev:package=5.7.14")
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.set_variation_storage_type()
  @runner.set_variation_mount_point
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "multicloud" do
  cid = VirtualMonkey::Toolbox::determine_cloud_id(@runner.servers.first)
  # Rackspace
  if cid == 232
    @runner.test_cloud_files
  # All other Clouds support both ROS and VOLUME
  elsif [1,2,3,4,5].include?(cid)
    @runner.test_ebs
    @runner.test_s3
  else
    @runner.test_volume
  end
end

after do
  @runner.cleanup_volumes
  @runner.cleanup_snapshots
end

before 'mount_point' do
  @runner.set_variation_mount_point('/mnt/monkey_test')
end

test 'mount_point' do
  transaction do
    @runner.test_volume
  end
end

after 'mount_point' do
  @runner.cleanup_volumes
  @runner.cleanup_snapshots
  @runner.set_variation_mount_point
end

test "reboot_operations" do
  @runner.run_reboot_operations
end


test "monitoring_checks" do
  @runner.check_monitoring
end

test "timestamp_override" do
  @runner.run_restore_with_timestamp_override
end

