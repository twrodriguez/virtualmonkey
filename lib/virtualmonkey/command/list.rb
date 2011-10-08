module VirtualMonkey
  module Command
    # Command Flags for List
    (@@command_flags ||= {}).merge!("list" => [:prefix, :verbose, :yes])

    # bin/monkey list -x
    def self.list(*args)
      self.init(*args)
      @@options = Trollop::options do
        eval(VirtualMonkey::Command::use_options)
      end
      DeploymentMonk.list(@@options[:prefix], @@options[:verbose])
    end
  end
end
