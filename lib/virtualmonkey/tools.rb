begin
  require '/var/spool/cloud/user-data.rb'
  require '/var/spool/cloud/meta-data.rb'
  ENV['I_AM_IN_EC2'] = "true"
rescue
  ENV['RS_API_URL'] = "#{ENV['USER']}-#{`hostname`}".strip
end

module VirtualMonkey
  module Tool
    def self.api0_1?
      unless class_variable_defined?("@@api0_1")
        begin
          Ec2SshKeyInternal.find_all
          @@api0_1 = true
        rescue
          @@api0_1 = false
        end
      end
      return @@api0_1
    end

    def self.setup_paths
      @@sgs_file = File.join("config", "cloud_variables", "security_groups.json")
      @@keys_file = File.join("config", "cloud_variables", "ec2_keys.json")
      @@ssh_dir = File.join(File.expand_path("~"), ".ssh")
      @@rest_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml")
    end

    def self.find_myself_in_api
      if ENV['I_AM_IN_EC2']
        myself = Server.find_with_filter('aws_id' => ENV['EC2_INSTANCE_ID']).first
        my_deploy = Deployment.find(myself['deployment_href'])
        ENV['MONKEY_SELF_SERVER_HREF'] = myself['href']
        ENV['MONKEY_SELF_DEPLOYMENT_HREF'] = myself['deployment_href']
        ENV['MONKEY_SELF_DEPLOYMENT_NAME'] = my_deploy.nickname
        return myself
      else
        return false
      end
    end

    def self.generate_ssh_keys(add_cloud = nil)
      setup_paths()

      cloud_ids = []
      for i in 1..5
        cloud_ids << i
      end
      cloud_ids << add_cloud.to_i if add_cloud

      multicloud_key_file = File.join(@@ssh_dir, "api_user_key")
      rest_settings = YAML::load(IO.read(@@rest_yaml))
      rest_settings[:ssh_keys] = [] unless rest_settings[:ssh_keys]
      multicloud_key_data = IO.read(multicloud_key_file) if File.exists?(multicloud_key_file)
      if File.exists?(@@keys_file)
        keys = JSON::parse(IO.read(@@keys_file))
      else
        keys = {}
      end

      cloud_ids.each { |cloud|
        next if cloud == 0 # Not a valid cloud ID
        next if keys["#{cloud}"] # We already have data for this cloud, skip
        if File.exists?(multicloud_key_file)
          key_name = "api_user_key"
        else
          if cloud <= 10
            key_name = "monkey-#{cloud}-#{ENV['RS_API_URL'].split("/").last}"
          else
            key_name = "monkey-1-#{ENV['RS_API_URL'].split("/").last}"
          end
        end
        if cloud <= 10
          found = nil
          if api0_1?
            found = Ec2SshKeyInternal.find_by_cloud_id("#{cloud}").select { |o| o.aws_key_name =~ /#{key_name}/ }.first
          end
          k = (found ? found : Ec2SshKey.create('aws_key_name' => key_name, 'cloud_id' => "#{cloud}"))
          keys["#{cloud}"] = {"ec2_ssh_key_href" => k.href,
                              "parameters" =>
                                {"PRIVATE_SSH_KEY" => "key:#{key_name}:#{cloud}"}
                              }
          # Generate Private Key Files
          priv_key_file = File.join(@@ssh_dir, "monkey-cloud-#{cloud}")
          File.open(priv_key_file, "w") { |f| f.write(k.aws_material) } unless File.exists?(priv_key_file)
        else
          # Use API user's managed ssh key
          puts "Using API user's managed ssh key"
          priv_key_file = multicloud_key_file
        end

        File.chmod(0700, priv_key_file)
        # Configure rest_connection config
        rest_settings[:ssh_keys] << priv_key_file unless rest_settings[:ssh_keys].contains?(priv_key_file)
      }

      keys_out = keys.to_json(:indent => "  ",
                              :object_nl => "\n",
                              :array_nl => "\n")
      rest_out = rest_settings.to_yaml
      File.open(@@keys_file, "w") { |f| f.write(keys_out) }
      File.open(@@rest_yaml, "w") { |f| f.write(rest_out) }
    end

    def destroy_ssh_keys
      setup_paths()

      cloud_ids = []
      for i in 1..5
        cloud_ids << i
      end

      rest_settings = YAML::load(IO.read(@@rest_yaml))

      key_name = "#{ENV['RS_API_URL'].split("/").last}"
      if api0_1?
        found = []
        cloud_ids.each { |c|
          found << Ec2SshKeyInternal.find_by_cloud_id("#{c}").select { |obj| obj.aws_key_name =~ /#{key_name}/ }
        }
        key_hrefs = found.select { |k| k.aws_key_name =~ /monkey/ }.map { |k| k.href }
      else
        keys = JSON::parse(IO.read(@@keys_file)) if File.exists?(@@keys_file)
        keys.reject! { |cloud,hash| hash["ec2_ssh_key_href"].nil? }
        key_hrefs = keys.map { |cloud,hash| hash["ec2_ssh_key_href"] }
      end
      key_hrefs.each { |href| Ec2SshKey.new('href' => href).destroy }
      File.delete(@@keys_file) if File.exists?(@@keys_file)
      rest_settings[:ssh_keys].each { |f| File.delete(f) if File.exists?(f) and f =~ /monkey/ }
    end

    def get_security_groups(add_cloud = nil)
      setup_paths()

      cloud_ids = []
      for i in 1..5
        cloud_ids << i
      end
      cloud_ids << add_cloud.to_i if add_cloud

      sgs = (File.exists?(@@sgs_file) ? JSON::parse(IO.read(@@sgs_file)) : {}) 

      cloud_ids.each { |cloud|
        next if cloud == 0 or sgs["#{cloud}"]
        if ENV['EC2_SECURITY_GROUP']
          sg_name = "#{ENV['EC2_SECURITY_GROUP']}"
        else
          raise "This script requires the environment variable EC2_SECURITY_GROUP to be set"
        end 
        if cloud <= 10
          found = Ec2SecurityGroup.find_by_cloud_id("#{cloud}").select { |o| o.aws_group_name =~ /#{sg_name}/ }.first
          if found
            sg = found
          else
            puts "Security Group '#{sg_name}' not found in cloud #{cloud}."
            default = Ec2SecurityGroup.find_by_cloud_id("#{cloud}").select { |o| o.aws_group_name =~ /default/ }.first
            sg = (default ? default : raise "Security Group 'default' not found in cloud #{cloud}.")
          end 
          sgs["#{cloud}"] = {"ec2_security_groups_href" => sg.href }
        else
          found = McSecurityGroup.find_by(:name, "#{cloud}") { |n| n =~ /#{sg_name}/ }.first
          if found
            sg = found
          else
            puts "Security Group '#{sg_name}' not found in cloud #{cloud}."
            default = McSecurityGroup.find_by_cloud_id("#{cloud}").select { |o| o.aws_group_name =~ /default/ }.first
            sg = (default ? default : raise "Security Group 'default' not found in cloud #{cloud}.")
          end 
          sgs["#{cloud}"] = {"security_group_hrefs" => [sg.href] }
        end 
      }

      sgs_out = sgs.to_json(:indent => "  ",
                            :object_nl => "\n",
                            :array_nl => "\n")

      File.open(@@sgs_file, "w") { |f| f.write(sgs_out) }
    end
  end
end
