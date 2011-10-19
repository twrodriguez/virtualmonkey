module VirtualMonkey
  module Command
    # monkey update_inputs --common_inputs blah.json --tag unique_name --cloud_variables blah.json
    add_command("update_inputs", [:common_inputs, :prefix, :config_file, :clouds]) do
      load_config_file if @@options[:config_file]
      @@dm = DeploymentMonk.new(@@options[:prefix], [], [], @@options[:allow_meta_monkey])
      @@dm.load_clouds(@@options[:clouds]) if @@options[:clouds]
      @@options[:common_inputs].each { |cipath| @@dm.load_common_inputs(cipath) } if @@options[:common_inputs]
      @@dm.update_inputs
      @@dm.set_server_params
    end
  end
end
