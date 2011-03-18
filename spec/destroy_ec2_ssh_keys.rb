require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'
require 'json'

begin
  require '/var/spool/cloud/user-data.rb'
rescue
  ENV['RS_API_URL'] = "#{ENV['USER']}-#{`hostname`}".strip
end

keys_file = File.join("..", "config", "cloud_variables", "ec2_keys.json")
ssh_dir = File.join(File.expand_path("~"), ".ssh")
rest_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml")
rest_settings = YAML::load(IO.read(rest_yaml))

if File.exists?(keys_file)
  keys = JSON::parse(IO.read(keys_file))
  keys.each { |cloud,hsh|
    found = Ec2SshKeyInternal.find_by_cloud_id(cloud).select { |n| n.href =~ /#{hsh['ec2_ssh_key_href']}/ }.first
    Ec2SshKey.new('href' => found.href).destroy if found
  }
  File.delete(keys_file)
else
  key_name = "#{ENV['RS_API_URL'].split("/").last}"
  found = Ec2SshKeyInternal.find_by_cloud_id("#{cloud}").select { |obj| obj.aws_key_name =~ /#{key_name}/ }
  found.each { |k| Ec2SshKey.new('href' => k.href).destroy }
end
rest_settings[:ssh_keys].each { |f| File.delete(f) if File.exists?(f) }
