module VirtualMonkey
  module Command
    def self.list(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:list]
        eval(VirtualMonkey::Command::use_options(:prefix, :verbose))
      end
      DeploymentMonk.list(@@options[:prefix], @@options[:verbose])
    end
  end 
end
