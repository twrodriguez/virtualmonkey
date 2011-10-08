module VirtualMonkey
  module Command
    # Command Flags for update_inputs
    (@@command_flags ||= {}).merge!("update_inputs" => [:common_inputs, :prefix, :config_file, :clouds])

    # monkey update_inputs --common_inputs blah.json --tag unique_name --cloud_variables blah.json
    def self.update_inputs(*args)
      self.init(*args)
      @@options = Trollop::options do
        eval(VirtualMonkey::Command::use_options)
      end

      load_config_file if @@options[:config_file]
      @@dm = DeploymentMonk.new(@@options[:prefix], [], [], @@options[:allow_meta_monkey])
      if @@options[:clouds]
        @@dm.load_clouds(@@options[:clouds])
#      elsif @@options[:cloud_variables]
#        @@options[:cloud_variables].each { |cvpath| @@dm.load_cloud_variables(cvpath) }
      end
      if @@options[:common_inputs]
        @@options[:common_inputs].each { |cipath| @@dm.load_common_inputs(cipath) }
      end
      @@dm.update_inputs
      @@dm.set_server_params
    end
  end
end
