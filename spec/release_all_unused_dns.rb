ENV['REST_CONNECTION_LOG'] = '/dev/null'

require 'rubygems'
require 'rest_connection'
require 'ruby-debug'
require 'pp'
require 'fog'

#sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test],
#                             :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])
sdb = Fog::AWS::SimpleDB.new()

sdb.list_domains.body["Domains"].select { |domain| domain =~ /dns/i || domain == "virtualmonkey_shared_resources" }.each { |domain|
  sdb.select("SELECT * from #{domain}").body["Items"].each { |k,v|
    begin
      print "Checking #{k.inspect} from domain #{domain.inspect}..."
      if v["owner"].first != "available"
        Deployment.find(v["owner"].first)
        puts "Deployment exists."
      else
        puts "already available."
      end
    rescue Exception => rest_exception
      if rest_exception.message =~ /404/
        begin
          sdb.put_attributes(domain, k, {"owner" => "available"}, :replace => ["owner"])
        rescue Excon::Errors::ServiceUnavailable
          print "being throttled..."
          sleep 5
          retry
        end
        puts "Freed #{k.inspect} from domain #{domain.inspect}."
        sleep 1
      end
    end
  }
}
