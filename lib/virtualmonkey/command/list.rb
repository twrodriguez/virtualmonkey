module VirtualMonkey
  module Command
    def self.list
      @options = Trollop::options do
        opt :tag, "List deployment set tag", :type => :string, :required => true
      end
      DeploymentMonk.new(@options[:tag]).deployments.each { |d| puts d.nickname }
    end
  end 
end
