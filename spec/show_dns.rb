require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'

@sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])
domains = ['virtualmonkey_awsdns', 'virtualmonkey_shared_resources', 'virtualmonkey_dyndns']

domains.each do |domain|
  free = @sdb.select("SELECT * from #{domain} where owner = 'available'")
  total = @sdb.select("SELECT * from #{domain}")
  puts "Domain: #{domain}"
  puts "->  #{free.body['Items'].size} available dns records out of #{total.body['Items'].size}"
end


