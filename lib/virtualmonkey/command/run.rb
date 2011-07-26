require 'eventmachine'
module VirtualMonkey
  module Command
  
# trollop supports Chronic for human readable dates. use with run command for delayed run?

# monkey run --feature --tag --only <regex to match on deploy nickname>
    def self.run(*args)
      if args.length > 1
        ARGV.replace args
      elsif args.length == 1
        ARGV.replace args.first.split(/ /)
      end
      raise "Aborting" unless VirtualMonkey::Toolbox::api0_1?
      @@options = Trollop::options do
        text @@available_commands[:run]
        eval(VirtualMonkey::Command::use_options( :config_file, :prefix, :only, :yes, :verbose, :qa, :tests,
                                                  :list_trainer, :keep, :terminate, :clouds, :no_resume))
      end

      load_config_file
      run_logic
    end
  end
end
