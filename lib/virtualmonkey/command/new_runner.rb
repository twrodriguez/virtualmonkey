module VirtualMonkey
  module Command
    # This command does all the steps create/run/conditionaly destroy
    def self.new_runner(*args)
      if args.length > 1
        ARGV.replace args
      elsif args.length == 1
        ARGV.replace args.first.split(/ /)
      end
      @@options = Trollop::options do
        text @@available_commands[:new_runner]
      end

      build_scenario_names()
      build_troop_config()
      write_common_inputs_file()
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
