# Uses Amazon SimpleDB to managed shared resources
require 'rest_connection'

class SharedDns
  attr_accessor :reservation
  attr_accessor :owner

  def self.new_sdb_connection
    Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test],
                           :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])
  end

  def self.release_from_all_domains(deploy_href)
    sdb = new_sdb_connection
    domains = sdb.list_domains.body["Domains"].select do |domain|
      domain =~ /dns/i || domain == "virtualmonkey_shared_resources"
    end
    domains.each do |domain|
      dns = SharedDns.new(domain)
      dns.reserve_dns(deploy_href)
      dns.release_dns
    end
  end

  def self.release_all_unused_domains
    sdb = new_sdb_connection
    domains = sdb.list_domains.body["Domains"].select do |domain|
      domain =~ /dns/i || domain == "virtualmonkey_shared_resources"
    end
    domains.each do |domain|
      sdb.select("SELECT * from #{domain}").body["Items"].each { |k,v|
        begin
          print "Checking #{k.inspect} from domain #{domain.inspect}..."
          if v["owner"].first != "available"
            Deployment.find(v["owner"].first)
            puts "Deployment exists.".apply_color(:red)
          else
            puts "already available.".apply_color(:green)
          end
        rescue Exception => rest_exception
          if rest_exception.message =~ /404/
            begin
              sdb.put_attributes(domain, k, {"owner" => "available"}, :replace => ["owner"])
            rescue Excon::Errors::ServiceUnavailable
              print "being throttled...".apply_color(:yellow)
              sleep 5
              retry
            end
            puts "Freed #{k.inspect} from domain #{domain.inspect}.".apply_color(:green)
            sleep 1
          end
        end
      }
    end
  end

  def initialize(domain = "virtualmonkey_shared_resources")
    @sdb = self.class.new_sdb_connection
    @domain = domain
    @reservation = nil
  end

  # set dns inputs on a deployment to match the current reservation
  # * deployment<~Deployment> the deployment to set inputs on
  def set_dns_inputs(deployment)
    sdb_result = @sdb.get_attributes(@domain, @reservation)

    set_these = sdb_result.body['Attributes'].reject {|k,v| k == 'owner'}
    deployment.set_inputs(set_these)

    blank_inputs = set_these.map { |k,v| [k, "text:"] }.to_h
    deployment.servers_no_reload.each do |s|
      s.set_next_inputs(blank_inputs)
      s.set_current_inputs(set_these)
    end
  end

  def reserve_dns(owner, timeout = 0)
    puts "Checking DNS reservation for #{owner}"
    result = @sdb.select("SELECT * from #{@domain} where owner = '#{owner}'")
    unless result.body["Items"].empty?
      puts "Reusing DNS reservation: " + @sdb.get_attributes(@domain, result.body["Items"].keys.first).body["Attributes"]["MASTER_DB_DNSNAME"].first.gsub(/^text:/,"")
    end
    if result.body["Items"].empty?
      result = @sdb.select("SELECT * from #{@domain} where owner = 'available'")
      if result.body["Items"].empty?
        SharedDns.release_all_unused_domains
        result = @sdb.select("SELECT * from #{@domain} where owner = 'available'")
        return false if result.body["Items"].empty?
      end
      item_name = result.body["Items"].keys.first
      puts "Aquired new DNS reservation: " + @sdb.get_attributes(@domain, item_name).body["Attributes"]["MASTER_DB_DNSNAME"].first.gsub(/^text:/,"")
      response = @sdb.put_attributes(@domain, item_name, {'owner' => owner}, :expect => {'owner' => "available"}, :replace => ['owner'])
    end
    @owner = owner
    @reservation = result.body["Items"].keys.first
  rescue Excon::Errors::ServiceUnavailable
    puts "Resuce: ServiceUnavailable"
    retry_reservation(owner, timeout)
  rescue Excon::Errors::Conflict
    puts "Resuce: Conflict"
    retry_reservation(owner, timeout)
  end

  def retry_reservation(owner, timeout)
    STDOUT.flush
    if timeout > 20
      return false
    end
    sleep(5)
    reserve_dns(owner, timeout + 1)
  end

  def release_all
    result = @sdb.select("SELECT * from #{@domain}")
    result.body['Items'].keys.each do |item_name|
      @sdb.put_attributes(@domain, item_name, {"owner" => "available"}, :replace => ["owner"])
    end
  end

  def release_dns(res = @reservation)
    raise "FATAL: could not release dns because there was no @reservation" unless res
    @sdb.put_attributes(@domain, res, {"owner" => "available"}, :replace => ["owner"])
    @reservation = nil
  end
end
