module VirtualMonkey
  module Command
    def self.list
      @@options = Trollop::options do
        opt :tag, "List deployment set tag", :type => :string, :required => true
        opt :verbose, "List the state of each server in the deployments as well"
      end
      DeploymentMonk.list(@@options[:tag], @@options[:verbose])
    end
  end 
end
