require File.join(File.dirname(__FILE__), "spec_helper")
require 'pp'
require 'ruby-debug'

@sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])
domains_old = ['virtualmonkey_awsdns']
domain_new = ['virtualmonkey_awsdns_new']

domains_old.each do |domain_old|
  total = @sdb.select("SELECT * from #{domain_old}")
  #puts "Domain: #{domain_old.body.to_s}"
 pp total  
@sdb.write("INSERT * from ##{domain_new}")
#puts "->  #{total.body.to_s}"
end


