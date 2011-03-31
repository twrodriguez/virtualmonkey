require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'
require 'json'

begin
  require '/var/spool/cloud/user-data.rb'
  require '/var/spool/cloud/meta-data.rb'
#  op_svrs = Server.find_by(:state) { |s| s == "operational" }
#  myself = op_svrs.each { |s| s.settings }.select { |s| s.dns_name =~ /#{ENV['EC2_PUBLIC_HOSTNAME']}/ }.first
  myself = Server.find_with_filter('aws_id' => ENV['EC2_INSTANCE_ID']).first
  my_deploy = Deployment.find(myself['deployment_href'])
  ENV['MONKEY_SELF_SERVER_HREF'] = myself['href']
  ENV['MONKEY_SELF_DEPLOYMENT_HREF'] = myself['deployment_href']
  ENV['MONKEY_SELF_DEPLOYMENT_NAME'] = my_deploy.nickname
rescue
end
