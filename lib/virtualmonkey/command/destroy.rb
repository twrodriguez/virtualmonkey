module VirtualMonkey
  module Command
    # Command Flags for Destroy
    (@@command_flags ||= {}).merge!("destroy" => [:config_file, :only, :keep, :prefix, :yes, :clouds, :verbose])

    # monkey destroy --tag unique_tag
    def self.destroy(*args)
      self.init(*args)
      @@options = Trollop::options do
        eval(VirtualMonkey::Command::use_options)
      end

      load_config_file
      @@dm = DeploymentMonk.new(@@options[:prefix], [], [], @@options[:allow_meta_monkey])
      select_only_logic("Really destroy")
      destroy_all_logic
    end

  end
end
