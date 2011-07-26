module VirtualMonkey
  module Command
    # This command does all the steps create/run/conditionaly destroy
    def self.import_deployment(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:import_deployment]
        eval(VirtualMonkey::Command::use_options(:deployment))
      end

      # Find Model Deployment
      deploy_name = @@options[:deployment]
      if @@options[:deployment]
        deployment = Deployment[deploy_name].first
        puts deployment.nickname
        accepted = ask("Is this the deployment that you wish to import? (y/n)", lambda { |ans| true if (ans =~ /^[yY]{1}/) })
      else
        accepted = false
      end

      while not accepted
        deploy_name = ask("What is the name of this model deployment?")
        deployments = Deployment[/#{deploy_name}/i]
        if deployments.length > 9
          say("Sorry, '#{deploy_name}' is too vague.")
        elsif deployments.length == 1
          deployment = deployments.first
          accepted = true
        elsif deployments.empty?
          say("Couldn't find any deployment named '#{deploy_name}'.")
        else
          i = choose do |menu|
            menu.prompt = "Which deployment did you mean?"
            menu.index = :number
            menu.choices(*(deployments.map { |d| d.nickname }))
          end
          deployment = deployments[i]
          accepted = true
        end
      end
      deployment.servers.each { |s| s.settings }
      
      # Build Scenario Names
      build_scenario_names(deployment.nickname)
      
      # Build Troop Config and Script_Array
      build_troop_config(deployment)
      

      # Extract Inputs from Deployment
      if VirtualMonkey::Toolbox::api1_5?
        mc_deployment = McDeployment[deployment.rs_id.to_i].first
        mc_deployment.show
        common_inputs = {}
        mc_deployment.inputs.each { |hsh| common_inputs[hsh["name"]] = hsh["value"] }

#        server_inputs = {}
#        deployment.servers_no_reload.each { |s|
#          if s.multicloud && s.current_instance
#            s.current_instance.inputs.each { |hsh|
#              # Do something?
#            }
#          end
#        }
        write_common_inputs_file(common_inputs)
      else
        write_common_inputs_file()
      end

      # Create files
      write_feature_file()
      write_troop_file()
      write_mixin_file()
      write_runner_file()

      say("Created common_inputs file:  #{@@common_inputs_file}")
      say("Created feature file:        #{@@feature_file}")
      say("Created config file:         #{@@troop_file}")
      say("Created mixin file:          #{@@mixin_file}")
      say("Created runner file:         #{@@runner_file}")

      say("\nScenario created! DON'T FORGET TO CUSTOMIZE THESE FILES!");
    end
  end
end
