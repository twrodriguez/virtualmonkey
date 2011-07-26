module VirtualMonkey
  module Command

# monkey create --server_template_ids 123,123 --common_inputs blah.json --feature simple.feature --tag unique_name --TBD:filter?
    def self.create(*args)
      raise "Aborting" unless VirtualMonkey::Toolbox::api0_1?
      if args.length > 1
        ARGV.replace args
      elsif args.length == 1
        ARGV.replace args.first.split(/ /)
      end
      @@options = Trollop::options do
        text @@available_commands[:create]
        eval(VirtualMonkey::Command::use_options( :config_file, :clouds, :only, :no_spot, :one_deploy, :prefix,
                                                  :yes, :verbose))
      end

      raise "--config_file is required" unless @@options[:config_file]
      #raise "You must select a single cloud id to create a singe deployment" if( @@options[:single_deployment] && (@@options[:cloud_override] == nil || @@options[:cloud_override].length != 1))  # you must select at most and at minimum 1 cloud to work on when the -z is selected
      load_config_file
      @@dm = DeploymentMonk.new(@@options[:prefix], @@options[:server_template_ids],[],false, @@options[:one_deploy])
      unless @@dm.deployments.size > 0
        create_logic
      else
        puts "Existing deployments matching --prefix #{@@options[:prefix]} found. Skipping deployment creation."
      end
    end
  end
end
