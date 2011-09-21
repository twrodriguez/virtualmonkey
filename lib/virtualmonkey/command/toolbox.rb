module VirtualMonkey
  module Command

    #
    # Generate ssh_keys.json, ~.ssh/ keys, and Cloud ssh key pairs
    #

    def self.generate_ssh_keys(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:generate_ssh_keys]
        opt :add_cloud, "Add a non-ec2 cloud to ssh_keys (takes the integer cloud id)", :type => :integer
        eval(VirtualMonkey::Command::use_options(:yes))
        # TODO: Add ssh_key_id_ary...
      end

      VirtualMonkey::Toolbox::generate_ssh_keys(@@options[:add_cloud])
      puts "SSH Keyfiles generated."
    end

    #
    # Destroy ssh_keys.json, ~.ssh/ keys, and Cloud ssh key pairs
    #

    def self.destroy_ssh_keys(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:destroy_ssh_keys]
        eval(VirtualMonkey::Command::use_options(:yes))
      end

      VirtualMonkey::Toolbox::destroy_ssh_keys()
      puts "SSH Keyfiles destroyed."
    end

    #
    # Populate security_groups.json
    #

    def self.populate_security_groups(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:populate_security_groups]
        opt :clouds, "Add security_groups to set of clouds (takes the integer cloud id)", :type => :integers, :short => "-i"
        opt :security_group_name, "Populate the file with this security group (will search for the name of the security group attached to the monkey instance, then 'default' by default)", :type => :string, :short => '-n'
        opt :overwrite, "Refresh values by replacing existing data"
        eval(VirtualMonkey::Command::use_options(:yes))
      end

      VirtualMonkey::Toolbox::populate_security_groups(@@options[:add_cloud], @@options[:security_group_name], @@options[:overwrite])
      puts "Security Group file populated."
    end

    #
    # Populate datacenters.json
    #

    def self.populate_datacenters(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:populate_datacenters]
        opt :add_cloud, "Add a non-ec2 cloud to datacenters (takes the integer cloud id)", :type => :integer
        opt :overwrite, "Refresh values by replacing existing data"
        eval(VirtualMonkey::Command::use_options(:yes))
      end

      VirtualMonkey::Toolbox::populate_datacenters(@@options[:add_cloud], @@options[:overwrite])
      puts "Datacenters file populated."
    end

    #
    # Populate the cloud_vars folder
    #

    def self.populate_all_cloud_vars(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:populate_all_cloud_vars]
        opt :force, "Forces command to continue if an exception is raised in a subcommand, populating as many files as possible."
        # TODO: Add ssh_key_id_ary...
        opt :security_group_name, "Populate the file with this security group (will search for the name of the security group attached to the monkey instance, then 'default' by default)", :type => :string, :short => '-n'
        opt :overwrite, "Refresh values by replacing existing data"
        eval(VirtualMonkey::Command::use_options(:yes))
      end

      VirtualMonkey::Toolbox::populate_all_cloud_vars(@@options[:force], @@options)
      puts "Cloud Variables folder populated."
    end

    #
    # Check API version connectivity
    #

    def self.api_check(*args)
      self.init(*args)
      @@options = Trollop::options do
        text @@available_commands[:api_check]
        opt :api_version, "Check to see if the monkey has RightScale API access for the given version (0.1, 1.0, or 1.5)", :type => :float, :required => true
        eval(VirtualMonkey::Command::use_options(:yes))
      end

      if [0.1, 1.0, 1.5].include?(@@options[:api_version])
        ret = VirtualMonkey::Toolbox.__send__("api#{@@options[:api_version]}?".gsub(/\./,"_"))
        puts "#{ret}"
      else
        STDERR.puts "Invalid version number: #{@@options[:api_version]}"
      end
    end
  end
end
