require 'ruby-debug'
module VirtualMonkey
  module Postgres
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix

    # sets the lineage for the deployment
    # * kind<~String> can be "chef" or nil
    def set_variation_lineage(kind = nil)
      @lineage = "testlineage#{resource_id(@deployment)}"
      if kind == "chef"
        @deployment.set_input('db/backup/lineage', "text:#{@lineage}")
        # unset all server level inputs in the deployment to ensure use of 
        # the setting from the deployment level
        @servers.each do |s|
          s.set_input('db/backup/lineage', "text:")
        end
      else
        @deployment.set_input('DB_LINEAGE_NAME', "text:#{@lineage}")
        # unset all server level inputs in the deployment to ensure use of 
        # the setting from the deployment level
        @servers.each do |s|
          s.set_input('DB_LINEAGE_NAME', "text:")
        end
      end
    end

    def set_variation_bucket
       bucket = "text:testingcandelete#{resource_id(@deployment)}"
      @deployment.set_input('remote_storage/default/container', bucket)
      # unset all server level inputs in the deployment to ensure use of 
      # the setting from the deployment level
      @servers.each do |s|
        s.set_input('remote_storage/default/container', "text:")
      end
    end

    # creates a PostgreSQL enabled EBS stripe on the server
    # * server<~Server> the server to create stripe on
    def create_stripe(server)
      options = {  
              "EBS_STRIPE_COUNT" => "text:#{@stripe_count}", 
              "DB_DUMP_BUCKET" => "ignore:$ignore",
              "DB_DUMP_FILENAME" => "ignore:$ignore",
              "STORAGE_ACCOUNT_ID" => "ignore:$ignore",
              "STORAGE_ACCOUNT_SECRET" => "ignore:$ignore",
              "DB_SCHEMA_NAME" => "ignore:$ignore",
              "EBS_TOTAL_VOLUME_GROUP_SIZE" => "text:1",
              "DB_LINEAGE_NAME" => "text:#{@lineage}" }
      run_script('create_stripe', server, options)
    end

    # Performs steps necessary to bootstrap a PostgreSQL Master server from a pristine state.
    # * server<~Server> the server to use as MASTER
    def config_master_from_scratch(server)
      behavior(:create_stripe, server)
      object_behavior(server, :spot_check_command, "service mysqld start")
#TODO the service name depends on the OS
#      server.spot_check_command("service mysql start")
      behavior(:run_query, "createdb -U postgres i-heart-monkey", server)
      behavior(:set_master_dns, server)
      # This sleep is to wait for DNS to settle - must sleep
      sleep 120
      behavior(:run_script, "backup", server)
    end

    # Runs a query on specified server.
    # * query<~String> a SQL query string to execute
    # * server<~Server> the server to run the query on 
    def run_query(query, server)
      query_command = "psql -U postgres -c \"#{query}\""
      server.spot_check_command(query_command)
    end

    # Sets DNS record for the Master server to point at server
    # * server<~Server> the server to use as MASTER
    def set_master_dns(server)
      run_script('master_init', server)
    end

    # Use the termination script to stop all the servers (this cleans up the volumes)
    def stop_all(wait=true)
      if script_to_run?('terminate')
        options = { "DB_TERMINATE_SAFETY" => "text:off" }
        @servers.each { |s| run_script('terminate', s, options) unless s.state == 'stopped' }
      else
        @servers.each { |s| s.stop }
      end

      wait_for_all("stopped") if wait
      # unset dns in our local cached copy..
      @servers.each { |s| s.params['dns-name'] = nil } 
    end

    # uses SharedDns to find an available set of DNS records and sets them on the deployment
    def setup_dns(domain)
# TODO should we just use the ID instead of the full href?
      owner=@deployment.href
      @dns = SharedDns.new(domain)
      raise "Unable to reserve DNS" unless @dns.reserve_dns(owner)
      @dns.set_dns_inputs(@deployment)
    end

    # releases records back into the shared DNS pool
    def release_dns
      @dns.release_dns
    end

    def restore_server(server)
      run_script("restore", server)
    end

    # These are PostgreSQL specific checks
    def run_checks
      # check that backup cron script exits success
      @servers.each do |server|
        chk1 = server.spot_check_command?("/usr/local/bin/pgsql-binary-backup.rb --max-snapshots 10 -D 4 -W 1 -M 1 -Y 1")
        raise "CRON BACKUPS FAILED TO EXEC, Aborting" unless (chk1) 
      end
    end

    # check that ulimit has been set correctly
    # XXX: DEPRECATED
    def ulimit_check
      @servers.each do |server|
        result = server.spot_check_command("su - postgres -s /bin/bash -c \"ulimit -n\"")
        raise "FATAL: ulimit wasn't set correctly" unless result[:output].to_i >= 1024
      end
    end
  end
end
