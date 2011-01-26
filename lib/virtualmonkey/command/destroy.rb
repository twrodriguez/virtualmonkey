module VirtualMonkey
  module Command
  
# monkey destroy --tag unique_tag
    def self.destroy
      @@options = Trollop::options do
        opt :tag, "Tag to match prefix of the deployments to destroy.", :type => :string, :required => true, :short => '-t'
        opt :terminate, "Terminate using the specified runner", :type => :string, :required => true, :short => "-r"
        opt :no_delete, "only terminate, no deletion."
        opt :yes, "Turn off confirmation for destroy operation"
      end
      begin
        eval("VirtualMonkey::#{@@options[:terminate]}.new('fgasvgreng243o520sdvnsals')") if @@options[:terminate]
      rescue Exception => e
        unless e.message =~ /Could not find a deployment named/
          @@options[:terminate] = "SimpleRunner" if @@options[:terminate]
        end
      end
      @@dm = DeploymentMonk.new(@@options[:tag])
      @@dm.deployments.each { |d| say d.nickname }
      unless options[:yes]
        confirm = ask("Really destroy these #{@@dm.deployments.size} deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
        raise "Aborting." unless confirm
      end

      destroy_all_logic
    end

  end
end
