module VirtualMonkey
  module Command

    # Generate ssh_keys.json, ~.ssh/ keys, and Cloud ssh key pairs

    add_command("generate_ssh_keys", [:yes, :clouds, :overwrite, :force, :ssh_keys]) do
      @@options[:ssh_keys] = JSON::parse(@@options[:ssh_keys]) if @@options[:ssh_keys]
      VirtualMonkey::Toolbox::generate_ssh_keys(@@options[:clouds],
                                                @@options[:overwrite],
                                                @@options[:force],
                                                @@options[:ssh_keys])
    end

    # Destroy ssh_keys.json, ~.ssh/ keys, and Cloud ssh key pairs
    add_command("destroy_ssh_keys", [:yes, :clouds, :force]) do
      VirtualMonkey::Toolbox::destroy_ssh_keys(@@options[:clouds], @@options[:force])
    end

    # Populate security_groups.json
    add_command("populate_security_groups", [:yes, :clouds, :overwrite, :force, :security_group_name]) do
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
    add_command("populate_all_cloud_vars", [:yes, :force, :overwrite, :clouds, :security_group_name]) do
      VirtualMonkey::Toolbox::populate_all_cloud_vars(@@options[:clouds], @@options)
    end

    # Check API version connectivity
    add_command("api_check", [:yes, :api_version]) do
      if @@options[:api_version]
        if [0.1, 1.0, 1.5].include?(@@options[:api_version])
          ret = VirtualMonkey::Toolbox.__send__("api#{@@options[:api_version]}?".gsub(/\./,"_"))
          puts "#{ret}"
        else
          error "Invalid version number: #{@@options[:api_version]}"
        end
      else
        hsh = [0.1, 1.0, 1.5].map_to_h { |ver| VirtualMonkey::Toolbox.__send__("api#{ver.gsub(/\./,"_")}?") }
        puts hsh.pretty_inspect
      end
    end
  end
end
