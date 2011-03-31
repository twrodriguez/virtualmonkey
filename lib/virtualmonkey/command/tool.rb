module VirtualMonkey
  module Command
    def self.tool
      @@options = Trollop::options do
        opt :generate_ssh_keys, "Generate EC2 ssh keys and populate monkey config files, and occurs AFTER --destroy_ssh_keys so that passing both can regenerate keys."
        opt :configure_security_groups, "Generate EC2 ssh keys and populate monkey config files"
        opt :destroy_ssh_keys, "Destroys all EC2 ssh keys created by --generate_ssh_keys. Does not destroy keys for non-EC2 clouds, and occurs BEFORE --generate_ssh_keys so that passing both can regenerate keys."
        opt :add_cloud, "Pass this to add a non-ec2 cloud to --generate_ssh_keys or --configure_security_groups options", :type => :integer
      end

      VirtualMonkey::Tool::destroy_ssh_keys() if @@options[:destroy_ssh_keys]
      VirtualMonkey::Tool::generate_ssh_keys(@@options[:add_cloud]) if @@options[:generate_ssh_keys]
      VirtualMonkey::Tool::configure_security_groups(@@options[:add_cloud]) if @@options[:configure_security_groups]
    end
  end 
end
