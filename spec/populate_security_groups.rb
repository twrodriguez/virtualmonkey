require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'
require 'json'

cmd = "bin/monkey populate_security_groups "
cmd += "--add-cloud #{ENV['ADD_CLOUD_SECURITY_GROUP']}" if ENV['ADD_CLOUD_SECURITY_GROUP']
`cd ..; #{cmd}`

exit(0)

begin
  require '/var/spool/cloud/meta-data.rb'
rescue
  ENV['RS_API_URL'] = "#{ENV['USER']}-#{`hostname`}".strip
end

# XXX DO NOT DELETE THIS COMMENT XXX
#Server.find_by(:state) { |s| s == "operational" }.each { |s| s.settings }.select { |s| s.dns_name =~ /#{ENV['EC2_PUBLIC_HOSTNAME']}/ }
# XXX DO NOT DELETE THIS COMMENT XXX

cloud_ids = []
for i in 1..5
  cloud_ids << i
end
cloud_ids << ENV['ADD_CLOUD_SECURITY_GROUP'].to_i if ENV['ADD_CLOUD_SECURITY_GROUP']

sgs_file = File.join("..", "config", "cloud_variables", "security_groups.json")
sgs = (File.exists?(sgs_file) ? JSON::parse(IO.read(sgs_file)) : {})

cloud_ids.each { |cloud|
  next if cloud == 0 or sgs["#{cloud}"]
  if ENV['EC2_SECURITY_GROUPS']
    sg_name = "#{ENV['EC2_SECURITY_GROUPS']}"
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
      raise "Security Group 'default' not found in cloud #{cloud}." unless default
      sg = default
    end
    sgs["#{cloud}"] = {"ec2_security_groups_href" => sg.href }
  else
    found = McSecurityGroup.find_by(:name, "#{cloud}") { |n| n =~ /#{sg_name}/ }.first
    if found
      sg = found
    else
      puts "Security Group '#{sg_name}' not found in cloud #{cloud}."
      default = McSecurityGroup.find_by_cloud_id("#{cloud}").select { |o| o.aws_group_name =~ /default/ }.first
      raise "Security Group 'default' not found in cloud #{cloud}." unless default
      sg = default
    end
    sgs["#{cloud}"] = {"security_group_hrefs" => [sg.href] }
  end
}

sgs_out = sgs.to_json(:indent => "  ",
                      :object_nl => "\n",
                      :array_nl => "\n")

File.open(sgs_file, "w") { |f| f.write(sgs_out) }
