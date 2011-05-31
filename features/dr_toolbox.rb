  @runner = VirtualMonkey::DrToolboxRunner.new(ENV['DEPLOYMENT'])
  @runner.set_var(:set_variation_lineage)
  @runner.set_var(:set_variation_container)
  @runner.set_var(:set_variation_storage_type)

  @runner.behavior(:stop_all)
  @runner.behavior(:launch_all)
  @runner.behavior(:wait_for_all, "operational")

  @runner.behavior(:test_multicloud)
