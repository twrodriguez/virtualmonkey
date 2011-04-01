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
  end 
end
