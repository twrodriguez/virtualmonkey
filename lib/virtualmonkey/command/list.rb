module VirtualMonkey
  module Command
    def self.list(*args)
      if args.length > 1
        ARGV.replace args
      elsif args.length == 1
        ARGV.replace args.first.split(/ /)
      end
      @@options = Trollop::options do
        text @@available_commands[:list]
        eval(VirtualMonkey::Command::use_options(:prefix, :verbose))
      end
      DeploymentMonk.list(@@options[:prefix], @@options[:verbose])
    end
  end 
end
