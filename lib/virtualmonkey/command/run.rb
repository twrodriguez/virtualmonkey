require 'eventmachine'
module VirtualMonkey
  module Command

# trollop supports Chronic for human readable dates. use with run command for delayed run?

# monkey run --feature --tag --only <regex to match on deploy nickname>
    def self.run(*args)
      unless VirtualMonkey::Toolbox::api0_1?
        STDERR.puts "Need Internal Testing API access to use this command."
        exit(1)
      end
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:run]
        eval(VirtualMonkey::Command::use_options( :config_file, :prefix, :only, :yes, :verbose, :tests,
                                                  :keep, :terminate, :clouds, :no_resume))
      end

      load_config_file
      run_logic
    end
  end
end
