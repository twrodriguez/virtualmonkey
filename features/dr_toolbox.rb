set :runner, VirtualMonkey::Runner::DrToolbox

clean_start do
  @runner.stop_all
end

before do
  @runner.tag_all_servers("rs_agent_dev:package=5.7.11")
  @runner.set_variation_lineage
  @runner.set_variation_container
  @runner.set_variation_storage_type("volume")
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
