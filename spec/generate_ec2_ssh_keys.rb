require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'
require 'json'

begin
  require '/var/spool/cloud/user-data.rb'
rescue
  ENV['RS_API_URL'] = "#{ENV['USER']}-#{`hostname`}".strip
end

# XXX DO NOT DELETE THIS COMMENT XXX
#Server.find_by(:state) { |s| s == "operational" }.each { |s| s.settings }.select { |s| s.dns_name =~ /#{ENV['EC2_PUBLIC_HOSTNAME']}/ }
# XXX DO NOT DELETE THIS COMMENT XXX

keys_file = File.join("..", "config", "cloud_variables", "ec2_keys.json")
ssh_dir = File.join(File.expand_path("~"), ".ssh")
rest_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml")
rest_settings = YAML::load(IO.read(rest_yaml))
rest_settings[:ssh_keys] = []

id_files = ["0-is-not-a-valid-cloud-id",
            "monkey-east",
            "monkey-eu",
            "monkey-west",
            "monkey-ap",
            "monkey-ap-northeast"]

keys = {}
id_files.each_index { |cloud|
  next if cloud == 0
  key_name = "monkey-#{cloud}-#{ENV['RS_API_URL'].split("/").last}"
  found = Ec2SshKeyInternal.find_by_cloud_id("#{cloud}").select { |obj| obj.aws_key_name =~ /#{key_name}/ }.first
  if found
    k = found
  else
    k = Ec2SshKey.create('aws_key_name' => key_name, 'cloud_id' => "#{cloud}")
  end
  keys["#{cloud}"] = {"ec2_ssh_key_href" => k.href,
                      "parameters" =>
                        {"PRIVATE_SSH_KEY" => "key:#{key_name}:#{cloud}"}
                      }
  # Generate Private Key Files
  priv_key_file = File.join(ssh_dir, id_files[cloud])
  File.open(priv_key_file, "w") { |f| f.write(k.aws_material) }
  File.chmod(0700, priv_key_file)
  # Configure rest_connection config
  rest_settings[:ssh_keys] << priv_key_file
}

keys_out = keys.to_json(:indent => "  ",
                        :object_nl => "\n",
                        :array_nl => "\n")
rest_out = rest_settings.to_yaml

File.open(keys_file, "w") { |f| f.write(keys_out) }
File.open(rest_yaml, "w") { |f| f.write(rest_out) }
