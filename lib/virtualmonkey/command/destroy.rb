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
        opt :only, "regex string to use for subselection matching on deployments.  Eg. --only x86_64", :type => :string
      end

      raise "Either --runner OR --feature is required" unless @@options[:feature] or @@options[:runner]
      @@options[:runner] = get_runner_class
      @@options[:terminate] = true
      raise "FATAL: Could not determine runner class" unless @@options[:runner]
      unless VirtualMonkey.const_defined?(@@options[:runner])
        puts "WARNING: VirtualMonkey::#{@@options[:runner]} is not a valid class. Defaulting to SimpleRunner."
        @@options[:runner] = "SimpleRunner"
      end

      @@dm = DeploymentMonk.new(@@options[:tag])
      if @@options[:only]
        @@do_these = @@dm.deployments.select { |d| d.nickname =~ /#{@@options[:only]}/ }
      end
      @@do_these.each { |d| say d.nickname }
      unless @@options[:yes]
        confirm = ask("Really destroy these #{@@do_these.size} deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
        raise "Aborting." unless confirm
      end

      destroy_all_logic
    end

  end
end
