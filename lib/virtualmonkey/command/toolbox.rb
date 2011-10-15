module VirtualMonkey
  module Command

    # Generate ssh_keys.json, ~.ssh/ keys, and Cloud ssh key pairs

    # TODO: Add ssh_key_id_ary...
    add_command("generate_ssh_keys", [:yes, :clouds, :overwrite, :force]) do
      VirtualMonkey::Toolbox::generate_ssh_keys(@@options[:clouds], @@options[:overwrite], @@options[:force])
    end

    # Destroy ssh_keys.json, ~.ssh/ keys, and Cloud ssh key pairs
    add_command("destroy_ssh_keys", [:yes, :clouds, :force]) do
      VirtualMonkey::Toolbox::destroy_ssh_keys(@@options[:clouds], @@options[:force])
    end

    # Populate security_groups.json
    add_command("populate_security_groups", [:yes, :clouds, :overwrite, :force], ["opt :security_group_name, \"Populate the file with this security group (will search for the name of the security group attached to the monkey instance, then 'default' by default)\", :type => :string, :short => '-n'"]) do
      VirtualMonkey::Toolbox::populate_security_groups(@@options[:clouds],
                                                       @@options[:security_group_name],
                                                       @@options[:overwrite],
                                                       @@options[:force])
    end

    # Populate datacenters.json
    add_command("populate_datacenters", [:yes, :clouds, :overwrite, :force]) do
      VirtualMonkey::Toolbox::populate_datacenters(@@options[:clouds], @@options[:overwrite], @@options[:force])
    end

    # Populate the cloud_vars folder
    add_command("populate_all_cloud_vars", [:yes, :force, :overwrite, :clouds], ["opt :security_group_name, \"Populate the file with this security group (will search for the name of the security group attached to the monkey instance, then 'default' by default)\", :type => :string, :short => '-n'"]) do
      VirtualMonkey::Toolbox::populate_all_cloud_vars(@@options[:clouds], @@options)
    end

    # Check API version connectivity
    add_command("api_check", [:yes], ["opt :api_version, 'Check to see if the monkey has RightScale API access for the given version (0.1, 1.0, or 1.5)', :type => :float, :required => true"]) do
      if [0.1, 1.0, 1.5].include?(@@options[:api_version])
        ret = VirtualMonkey::Toolbox.__send__("api#{@@options[:api_version]}?".gsub(/\./,"_"))
        puts "#{ret}"
      else
        error "Invalid version number: #{@@options[:api_version]}"
      end
    end
  end
end
