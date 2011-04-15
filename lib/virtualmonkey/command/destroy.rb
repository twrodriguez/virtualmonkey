module VirtualMonkey
  module Command
  
# monkey destroy --tag unique_tag
    def self.destroy
      @@options = Trollop::options do
        opt :tag, "Tag to match prefix of the deployments to destroy.", :type => :string, :required => true, :short => '-t'
        opt :runner, "Terminate using the specified runner", :type => :string, :short => "-r"
        opt :feature, "Terminate using the runner from the specified feature file", :type => :string, :short => "-f"
        opt :no_delete, "only terminate, no deletion."
        opt :yes, "Turn off confirmation for destroy operation"
      end

      raise "Either --runner OR --feature is required" unless @@options[:feature] or @@options[:runner]
      @@options[:runner] = get_runner_class
      @@options[:terminate] = true
      unless VirtualMonkey.const_defined?(@@options[:runner])
        puts "WARNING: VirtualMonkey::#{@@options[:runner]} is not a valid class. Defaulting to SimpleRunner."
        @@options[:runner] = "SimpleRunner"
      end

      @@dm = DeploymentMonk.new(@@options[:tag])
      @@dm.deployments.each { |d| say d.nickname }
      unless @@options[:yes]
        confirm = ask("Really destroy these #{@@dm.deployments.size} deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
        raise "Aborting." unless confirm
      end

      destroy_all_logic
    end

  end
end
