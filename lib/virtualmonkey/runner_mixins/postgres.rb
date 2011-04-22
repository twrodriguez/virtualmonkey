require 'ruby-debug'
module VirtualMonkey
  module Postgres
    include VirtualMonkey::DeploymentBase
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
              "DBAPPLICATION_USER" => "text:someuser",
              "DB_DUMP_BUCKET" => "ignore:$ignore",
              "DB_DUMP_FILENAME" => "ignore:$ignore",
              "STORAGE_ACCOUNT_ID" => "ignore:$ignore",
              "STORAGE_ACCOUNT_SECRET" => "ignore:$ignore",
              "DB_NAME" => "ignore:$ignore",
              "DBAPPLICATION_PASSWORD" => "text:somepass",
              "EBS_TOTAL_VOLUME_GROUP_SIZE" => "text:1",
              "DB_LINEAGE_NAME" => "text:#{@lineage}" }
      run_script('create_stripe', server, options)
    end

    # creates a MySQL enabled EBS stripe on the server and uses the dumpfile to restore the DB
    def create_stripe_from_dumpfile(server)
      options = { 
              "EBS_STRIPE_COUNT" => "text:#{@stripe_count}",
              "EBS_VOLUME_SIZE" => "text:1",
              "DBAPPLICATION_USER" => "text:someuser",
#TODO: un-hard code the bucket and dumpfile
#              "DB_MYSQLDUMP_BUCKET" => "text:#{@bucket}",
#              "DB_MYSQLDUMP_FILENAME" => "text:#{@dumpfile}",
              "DB_DUMP_BUCKET" => "text:rightscale_tutorials",
              "DB_DUMP_FILENAME" => "text:phptest.sql.gz",
              "STORAGE_ACCOUNT_ID" => "cred:AWS_ACCESS_KEY_ID",
              "STORAGE_ACCOUNT_SECRET" => "cred:AWS_SECRET_ACCESS_KEY",
              "DB_NAME" => "text:monkey_schema",
              "DBAPPLICATION_PASSWORD" => "text:somepass",
              "EBS_TOTAL_VOLUME_GROUP_SIZE" => "text:1",
              "DB_LINEAGE_NAME" => "text:#{@lineage}" }
      run_script('create_stripe', server, options)
    end

    # Performs steps necessary to bootstrap a MySQL Master server from a pristine state using a dumpfile.
    # * server<~Server> the server to use as MASTER
    def config_master_from_scratch_from_dumpfile(server)
      behavior(:create_stripe_from_dumpfile, server)
      behavior(:run_query, "CREATE DATABASE i_heart_monkey", server)
      behavior(:set_master_dns, server)
      # This sleep is to wait for DNS to settle - must sleep
      sleep 120
      behavior(:run_script, "backup", server)
    end

    # Performs steps necessary to bootstrap a PostgreSQL Master server from a pristine state.
    # * server<~Server> the server to use as MASTER
    def config_master_from_scratch(server)
      behavior(:create_stripe, server)
      behavior(:run_query, "CREATE DATABASE i_heart_monkey", server)
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

    def promote_server(server)
      run_script("promote", server)
    end

    def slave_init_server(server)
      run_script("slave_init", server)
    end

    def restore_server(server)
      run_script("restore", server)
    end

    # These are PostgreSQL specific checks
    def run_checks
      # check that backup cron script exits success
      @servers.each do |server|
        chk1 = server.spot_check_command?("/usr/local/bin/pgsql-binary-backup.rb --if-master --max-snapshots 10 -D 4 -W 1 -M 1 -Y 1")

        chk2 = server.spot_check_command?("/usr/local/bin/pgsql-binary-backup.rb --if-slave --max-snapshots 10 -D 4 -W 1 -M 1 -Y 1")

        raise "CRON BACKUPS FAILED TO EXEC, Aborting" unless (chk1 || chk2) 
      end
    end

    def init_slave_from_slave_backup
      behavior(:config_master_from_scratch, s_one)
      behavior(:run_script, "freeze_backups", s_one)
      behavior(:wait_for_snapshots)
      behavior(:slave_init_server, s_two)
      behavior(:run_script, "backup", s_two)
      s_two.relaunch
      s_one['dns-name'] = nil
      s_two.wait_for_operational_with_dns
      behavior(:wait_for_snapshots)
      #sleep 300
      behavior(:slave_init_server, s_two)
    end

    def run_promotion_operations
      behavior(:config_master_from_scratch, s_one)
      object_behavior(s_one, :relaunch)
      s_one.dns_name = nil
      behavior(:wait_for_snapshots)
# need to wait for ebs snapshot, otherwise this could easily fail
      behavior(:restore_server, s_two)
      object_behavior(s_one, :wait_for_operational_with_dns)
      behavior(:slave_init_server, s_one)
      behavior(:promote_server, s_one)
    end

    def run_reboot_operations
# Duplicate code here because we need to wait between the master and the slave time
      #reboot_all(true) # serially_reboot = true
      @servers.each do |s|
        object_behavior(s, :reboot, true)
        object_behavior(s, :wait_for_state, "operational")
      end
      behavior(:wait_for_all, "operational")
      behavior(:run_reboot_checks)
    end

    # This is where we perform multiple checks on the deployment after a reboot.
    def run_reboot_checks
      # one simple check we can do is the backup.  Backup can fail if anything is amiss
      @servers.each do |server|
        behavior(:run_script, "backup", server)
      end
    end

    def run_restore_with_timestamp_override
      object_behavior(s_one, :relaunch)
      s_one.dns_name = nil
      object_behavior(s_one, :wait_for_operational_with_dns)
      behavior(:run_script, 'restore', s_one, { "OPT_DB_RESTORE_TIMESTAMP_OVERRIDE" => "text:#{find_snapshot_timestamp}" })
    end

# Check for specific MySQL data.
    def check_mysql_monitoring
      mysql_plugins = [
                        {"plugin_name"=>"mysql", "plugin_type"=>"mysql_commands-delete"},
                        {"plugin_name"=>"mysql", "plugin_type"=>"mysql_commands-create_db"},
                        {"plugin_name"=>"mysql", "plugin_type"=>"mysql_commands-create_table"},
                        {"plugin_name"=>"mysql", "plugin_type"=>"mysql_commands-insert"},
                        {"plugin_name"=>"mysql", "plugin_type"=>"mysql_commands-show_databases"}
                      ]
      @servers.each do |server|
        unless server.multicloud
#mysql commands to generate data for collectd to return
          for ii in 1...100
#TODO: have to select db with every call.  figure a better way to do this and get rid of fast and ugly
# cut and past hack.
            behavior(:run_query, "show databases", server)
            behavior(:run_query, "create database test#{ii}", server)
            behavior(:run_query, "use test#{ii}; create table test#{ii}(test text)", server)
            behavior(:run_query, "use test#{ii};show tables", server)
            behavior(:run_query, "use test#{ii};insert into test#{ii} values ('1')", server)
            behavior(:run_query, "use test#{ii};update test#{ii} set test='2'", server)
            behavior(:run_query, "use test#{ii};select * from test#{ii}", server)
            behavior(:run_query, "use test#{ii};delete from test#{ii}", server)
            behavior(:run_query, "show variables", server)
            behavior(:run_query, "show status", server)
            behavior(:run_query, "use test#{ii};grant select on test.* to root", server)
            behavior(:run_query, "use test#{ii};alter table test#{ii} rename to test2#{ii}", server)
          end
          mysql_plugins.each do |plugin|
            monitor = server.get_sketchy_data({'start' => -60,
                                               'end' => -20,
                                               'plugin_name' => plugin['plugin_name'],
                                               'plugin_type' => plugin['plugin_type']})
            value = monitor['data']['value']
            raise "No #{plugin['plugin_name']}-#{plugin['plugin_type']} data" unless value.length > 0
            # Need to check for that there is at least one non 0 value returned.
            for nn in 0...value.length
              if value[nn] > 0
                break
              end
            end
            raise "No #{plugin['plugin_name']}-#{plugin['plugin_type']} time" unless nn < value.length
            puts "Monitoring is OK for #{plugin['plugin_name']}-#{plugin['plugin_type']}"
          end
        end
      end
    end

    def create_master
      config_master_from_scratch(s_one)
    end

    def create_master_from_dumpfile
      config_master_from_scratch_from_dumpfile(s_one)
    end
  end
end
