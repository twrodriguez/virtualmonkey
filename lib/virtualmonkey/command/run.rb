require 'eventmachine'
module VirtualMonkey
  module Command
    # Command Flags for Run
    (@@command_flags ||= {}).merge!("run" => [:config_file, :prefix, :only, :yes, :verbose, :tests, :keep,
                                              :terminate, :clouds, :no_resume, :report_tags,
                                              :report_metadata])

    # TODO trollop supports Chronic for human readable dates. use with run command for delayed run?

    # monkey run --feature --tag --only <regex to match on deploy nickname>
    def self.run(*args)
      unless VirtualMonkey::Toolbox::api0_1?
        warn "Need Internal Testing API access to use this command.".red
        exit(1)
      end
      self.init(*args)
      @@options = Trollop::options do
        eval(VirtualMonkey::Command::use_options)
      end

      load_config_file
      run_logic
    end
  end
end
