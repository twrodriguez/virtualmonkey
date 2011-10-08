module VirtualMonkey
  module Command
    # Command Flags for Troop
    (@@command_flags ||= {}).merge!("troop" => [:config_file, :no_spot, :prefix, :use_mci, :verbose, :yes,
                                                :one_deploy, :keep, :clouds, :only, :tests, :no_resume,
                                                :revisions, :report_tags, :report_metadata])

    # This command does all the steps create/run/conditionaly destroy
    def self.troop(*args)
      unless VirtualMonkey::Toolbox::api0_1?
        warn "Need Internal Testing API access to use this command.".red
        exit(1)
      end
      self.init(*args)
      @@options = Trollop::options do
        eval(VirtualMonkey::Command::use_options)
      end
      #raise "You must select a single cloud id to create a singe deployment" if( @@options[:single_deployment] && (@@options[:cloud_override] == nil || @@options[:cloud_override].length != 1))  # you must select at most and at minimum 1 cloud to work on when the -z is selected
      # Execute Main
      load_config_file

      # CREATE PHASE
      @@dm = DeploymentMonk.new(@@options[:prefix],
                                @@options[:server_template_ids],
                                [],
                                @@options[:allow_meta_monkey],
                                @@options[:single_deployment])
      unless @@dm.deployments.size > 0
        create_logic
      else
        puts "Existing deployments matching --prefix #{@@options[:prefix]} found. Skipping deployment creation."
      end

      run_logic
      puts "Troop done."
    end
  end
end
