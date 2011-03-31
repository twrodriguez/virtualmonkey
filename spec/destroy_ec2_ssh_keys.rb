require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'
require 'json'

begin
  require '/var/spool/cloud/user-data.rb'
rescue
  ENV['RS_API_URL'] = "#{ENV['USER']}-#{`hostname`}".strip
end

cloud_ids = []
for i in 1..5
  cloud_ids << i
end 


keys_file = File.join("..", "config", "cloud_variables", "ec2_keys.json")
ssh_dir = File.join(File.expand_path("~"), ".ssh")
rest_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml")
rest_settings = YAML::load(IO.read(rest_yaml))

api0_1 = false
begin
  api0_1 = Ec2SshKeyInternal.find_all
rescue
end

key_name = "#{ENV['RS_API_URL'].split("/").last}"
if api0_1
  found = []
  cloud_ids.each { |c| 
    found << Ec2SshKeyInternal.find_by_cloud_id("#{c}").select { |obj| obj.aws_key_name =~ /#{key_name}/ }
  }  
  key_hrefs = found.select { |k| k.aws_key_name =~ /monkey/ }.map { |k| k.href }
else
  keys = JSON::parse(IO.read(keys_file)) if File.exists?(keys_file)
  keys.reject! { |cloud,hash| hash["ec2_ssh_key_href"].nil? }
  key_hrefs = keys.map { |cloud,hash| hash["ec2_ssh_key_href"] }
end
key_hrefs.each { |href| Ec2SshKey.new('href' => href).destroy } if key_hrefs
File.delete(keys_file) if File.exists?(keys_file)
rest_settings[:ssh_keys].each { |f| File.delete(f) if File.exists?(f) and f =~ /monkey/ }
