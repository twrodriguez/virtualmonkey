require 'rubygems'
require 'virtualmonkey'

@sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])

@domain="dnsmadeeasy_new"



Master_DB_DNSID = ["not used", "text:5264480","text:5264481", "text:5264482", "text:5264483", "text:5264484", "text:5264485","text:5264487","text:5264489","text:5264499","text:5264493","text:5264497","text:5264498", "text:5425624", "text:5425626","text:5425628","text:5425821","text:5425824","text:5425831" ]
18.times do |num|
  item_name="dnsmadeeasy#{num+1}"
  attributes=
      {"SLAVE_DB_DNSID"=>["#{Master_DB_DNSID[num+1]}"],
       "MASTER_DB_DNSID"=>["#{Master_DB_DNSID[num+1]}"],
       "sys_dns/id"=>["#{Master_DB_DNSID[num+1]}"],
       "DNS_USER"=>["cred:DNSMADEEASY_TEST_USER"],
       "sys_dns/user"=>["cred:DNSMADEEASY_TEST_USER"],
       "DNS_PASSWORD"=>["cred:DNSMADEEASY_TEST_PASSWORD"],
       "sys_dns/password"=>["cred:DNSMADEEASY_TEST_PASSWORD"],
       "DNS_PROVIDER"=>["text:DNSMadeEasy"],
       "owner"=>["available"],
       "db_mysql/fqdn"=>["text:vmonk#{num+1}-master.test.rightscale.com"],
       "MASTER_DB_DNSNAME"=>["text:vmonk#{num+1}-master.test.rightscale.com"]}
      
  response = @sdb.put_attributes(@domain, item_name, attributes)
end

