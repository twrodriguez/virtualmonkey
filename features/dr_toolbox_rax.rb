  @runner = VirtualMonkey::DrToolboxRunner.new(ENV['DEPLOYMENT'])
  @runner.set_var(:set_variation_lineage)
  @runner.set_var(:set_variation_container)
  @runner.set_var(:set_variation_storage_type, "ros")

  @runner.behavior(:stop_all)
  @runner.behavior(:launch_all)
  @runner.behavior(:wait_for_all, "operational")

  #@runner.behavior(:test_s3)
  #@runner.behavior(:test_ebs)
  #@runner.behavior(:test_cloud_files)
