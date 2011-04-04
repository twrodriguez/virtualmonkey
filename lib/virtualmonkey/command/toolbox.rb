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

      if [0.1, 1.0, 1.5].contains?(@@options[:api_version])
        ret = VirtualMonkey::Toolbox.__send__("api#{@@options[:api_version]}?".gsub(/\./,"_"))
        puts "#{ret}"
      else
        STDERR.puts "Invalid version number: #{@@options[:api_version]}"
      end
    end
  end 
end
