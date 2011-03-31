module VirtualMonkey
  module Command
    def self.list
      @@options = Trollop::options do
        opt :tag, "List deployment set tag", :type => :string, :required => true
      end
      DeploymentMonk.list(@@options[:tag])
    end
  end 
end
