module VirtualMonkey
  module Command
    def self.generate_ssh_keys
      @@options = Trollop::options do
        opt :add_cloud, "Add a non-ec2 cloud to ssh_keys (takes the integer cloud id)", :type => :integer
      end

      VirtualMonkey::Toolbox::generate_ssh_keys(@@options[:add_cloud])
      puts "SSH Keyfiles generated."
    end

    def self.destroy_ssh_keys
      @@options = Trollop::options do
        text "Destroys ssh keys"
      end

      VirtualMonkey::Toolbox::destroy_ssh_keys()
      puts "SSH Keyfiles destroyed."
    end

    def self.populate_security_groups
      @@options = Trollop::options do
        opt :add_cloud, "Add a non-ec2 cloud to security_groups (takes the integer cloud id)", :type => :integer
      end

      VirtualMonkey::Toolbox::populate_security_groups(@@options[:add_cloud])
      puts "Security Group file populated."
    end

    def self.api_check
      @@options = Trollop::options do
        opt :api_version, "Check to see if the monkey has RightScale API access for the given version (0.1, 1.0, or 1.5)", :type => :float, :required => true
      end

      if [0.1, 1.0, 1.5].include?(@@options[:api_version])
        ret = VirtualMonkey::Toolbox.__send__("api#{@@options[:api_version]}?".gsub(/\./,"_"))
        puts "#{ret}"
      else
        STDERR.puts "Invalid version number: #{@@options[:api_version]}"
      end
    end

    def self.audit_logs
      @@options = Trollop::options do
        opt :tag, "Tag to match prefix of the deployments.", :type => :string, :required => true, :short => "-t"
        opt :only, "regex string to use for subselection matching on deployments.  Eg. --only x86_64", :type => :string
        opt :runner, "Use the specified runner class to flag messages.", :type => :string, :short => "-r"
        opt :feature, "Use the runner class from the specified feature file to flag messages.", :type => :string, :short => "-f"
        opt :list_trainer, "run through the interactive white- and black-list trainer."
        opt :qa, "Performs a strict black-list check, ignoring white-list entries"
      end

      @@options[:runner] = get_runner_class
      @@dm = DeploymentMonk.new(@@options[:tag])
      @@do_these ||= @@dm.deployments
      if @@options[:only]
        @@do_these = @@do_these.select { |d| d.nickname =~ /#{@@options[:only]}/ }
      end

      @@do_these.each { |d| say d.nickname }
      puts "Note: This tool is not as effective without an associated runner class." unless @@options[:runner]
      confirm = ask("Train lists on these #{@@do_these.length} deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
      raise "Aborting." unless confirm

      if @@options[:runner]
        @@do_these.each { |d| audit_log_deployment_logic(d, @@options[:list_trainer]) }
      else
        mc = MessageCheck.new({}, @@options[:qa])
        puts mc.check_messages(@@do_these, :interactive)
      end
    end
  end 
end
