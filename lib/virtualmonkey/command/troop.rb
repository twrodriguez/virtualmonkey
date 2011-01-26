module VirtualMonkey
  module Command
    # This command does all the steps create/run/conditionaly destroy
    def self.troop
      @@options = Trollop::options do
        text "This command performs all the operations of the monkey in one execution.  Create/Run/Destroy"
        opt :file, "troop config, see config/troop/*sample.json for example format", :type => :string, :required => true
        opt :no_spot, "do not use spot instances"
        opt :step, "use the troop config file to do either: create, run, or destroy", :type => :string
        opt :tag, "add an additional tag to the deployments", :type => :string
        opt :create, "interactive mode: create troop config"
        opt :mci_override, "list of mcis to use instead of the ones from the server template. expects full hrefs.", :type => :string, :multi => true, :required => false
        opt :no_delete, "only terminate, no deletion.", :short => "-d"
        opt :verbose, "Print all output to STDOUT as well as the log files", :short => "-v"
      end

      # PATHs SETUP
      features_glob = Dir.glob(File.join(@@features_dir, "**")).collect { |c| File.basename(c) }
      cloud_variables_glob = Dir.glob(File.join(@@cv_dir, "**")).collect { |c| File.basename(c) }
      common_inputs_glob = Dir.glob(File.join(@@ci_dir, "**")).collect { |c| File.basename(c) }
      
      # CREATE NEW CONFIG
      if @@options[:create]
        troop_config = {}
        troop_config[:tag] = ask("What tag to use for creating the deployments?")
        troop_config[:server_template_ids] = ask("What Server Template ids would you like to use to create the deployments (comma delimited)?").split(",")
        troop_config[:server_template_ids].each {|st| st.strip!}

        troop_config[:runner] = 
          choose do |menu|
            menu.prompt = "What kind of deployment is this (runner type)?"
            menu.choice("MysqlToolboxRunner")
            menu.choice("MysqlRunner")
            menu.choice("SimpleRunner")
          end

        troop_config[:cloud_variables] =
          choose do |menu|
            menu.prompt = "Which cloud_variables config file?"
            menu.index = :number
            menu.choices(*cloud_variables_glob)
          end

        troop_config[:common_inputs] =
          choose do |menu|
            menu.prompt = "Which common_inputs config file?"
            menu.index = :number
            menu.choices(*common_inputs_glob)
          end

        troop_config[:feature] = 
          choose do |menu|
            menu.prompt = "Which feature file?"
            menu.index = :number
            menu.choices(*features_glob)
          end
        
        write_out = troop_config.to_json( :indent => "  ", 
                                          :object_nl => "\n",
                                          :array_nl => "\n" )
        File.open(@@options[:file], "w") { |f| f.write(write_out) }
        say("created config file #{@@options[:file]}")
        say("Done.")
      else
        # Execute Main
        config = JSON::parse(IO.read(@@options[:file]))
        @@options[:tag] += "-" if @@options[:tag]
        @@options[:tag] = "" unless @@options[:tag]
        @@options[:tag] += config['tag']
        @@options[:step] = "all" unless @@options[:step]
        @@options[:cloud_variables] = File.join(@@cv_dir, config['cloud_variables'])
        @@options[:common_inputs] = config['common_inputs'].map { |cipath| File.join(@@ci_dir, cipath) }
        @@options[:feature] = File.join(@@feature_dir, config['feature'])
        @@options[:terminate] = config['runner']
        unless @@options[:step] =~ /(all)|(create)|(run)|(destroy)/
          raise "Invalid --step argument. Valid steps are: 'all', 'create', 'run', or 'destroy'"
        end

        # CREATE PHASE
        if @@options[:step] =~ /((all)|(create))/
          @@dm = DeploymentMonk.new(@@options[:tag], config['server_template_ids'])
          unless @@dm.deployments.size > 0
            create_logic # NEW INTERNAL COMMAND
          else
            puts "Existing deployments matching --tag #{@@options[:tag]} found. Skipping deployment creation."
          end
        end

        # RUN PHASE
        if @@options[:step] =~ /((all)|(run))/
          @@dm = DeploymentMonk.new(@@options[:tag]) if @@options[:step] =~ /run/
          run_logic # NEW INTERNAL COMMAND
        end

        # DESTROY PHASE
        if @@options[:step] =~ /destroy/
          @@dm = DeploymentMonk.new(@@options[:tag])
          destroy_all_logic # NEW INTERNAL COMMAND
        end
      end
      puts "Troop done."
    end
  end
end
