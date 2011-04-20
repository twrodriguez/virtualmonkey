require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'
require 'json'

cmd = "bin/monkey generate_ssh_keys "
cmd += "--add-cloud #{ENV['ADD_CLOUD_SSH_KEY']}" if ENV['ADD_CLOUD_SSH_KEY']
`cd ..; #{cmd}`

exit(0)

# Don't execute beyond here...legacy code

begin
  require '/var/spool/cloud/user-data.rb'
rescue
  ENV['RS_API_URL'] = "#{ENV['USER']}-#{`hostname`}".strip
end

cloud_ids = []
for i in 1..5
  cloud_ids << i
end
cloud_ids << ENV['ADD_CLOUD_SSH_KEY'].to_i if ENV['ADD_CLOUD_SSH_KEY']

keys_file = File.join("..", "config", "cloud_variables", "ec2_keys.json")
ssh_dir = File.join(File.expand_path("~"), ".ssh")
rest_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml")
rest_settings = YAML::load(IO.read(rest_yaml))
rest_settings[:ssh_keys] = [] unless rest_settings[:ssh_keys]
multicloud_key_file = File.join(ssh_dir, "api_user_key")
multicloud_key_data = IO.read(multicloud_key_file) if File.exists?(multicloud_key_file)
if File.exists?(keys_file)
  keys = JSON::parse(IO.read(keys_file))
else
  keys = {}
end

api0_1 = false
begin
  api0_1 = Ec2SshKeyInternal.find_all
rescue
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
    if api0_1
      found = Ec2SshKeyInternal.find_by_cloud_id("#{cloud}").select { |o| o.aws_key_name =~ /#{key_name}/ }.first
    end
    k = (found ? found : Ec2SshKey.create('aws_key_name' => key_name, 'cloud_id' => "#{cloud}"))
    keys["#{cloud}"] = {"ec2_ssh_key_href" => k.href,
                        "parameters" =>
                          {"PRIVATE_SSH_KEY" => "key:#{key_name}:#{cloud}"}
                        }
    # Generate Private Key Files
    priv_key_file = File.join(ssh_dir, "monkey-cloud-#{cloud}")
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

File.open(keys_file, "w") { |f| f.write(keys_out) }
File.open(rest_yaml, "w") { |f| f.write(rest_out) }
