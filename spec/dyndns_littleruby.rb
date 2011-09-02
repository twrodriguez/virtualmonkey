require 'rubygems'
require 'virtualmonkey'

@sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])

@domain="virtualmonkey_dyndns_new"

1.times do |num|
  item_name="awsdns#{num}"
  attributes=
      {"SLAVE_DB_DNSID"=>["text:rightscale-test#{num}.dyndns.org"],
       "MASTER_DB_DNSID"=>["text:rightscale-test.dyndns.org"],
       "sys_dns/id"=>["text:rightscale-test.dyndns.org"],
       "DNS_USER"=>["cred:DYNDNS-USER"],
       "sys_dns/user"=>["cred:DYNDNS-USER"],
       "DNS_PASSWORD"=>["cred:DYNDNS-PASSWORD"],
       "sys_dns/password"=>["cred:DYNDNS-PASSWORD"],
       "DNS_PROVIDER"=>["text:DYNDNS"],
       "owner"=>["available"],
       "db_mysql/fqdn"=>["text:rightscale-test.dyndns.org"],
       "MASTER_DB_DNSNAME"=>["text:rightscale-test.dyndns.org"]}
      
  response = @sdb.put_attributes(@domain, item_name, attributes)
end

