module VirtualMonkey
  module Mixin
    module ChefMysql
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::EBS
      attr_accessor :scripts_to_run
      attr_accessor :db_ebs_prefix
  
      def mysql_servers
        res = []
        @servers.each do |server|
          st = ServerTemplate.find(resource_id(server.server_template_href))
          if st.nickname =~ /Database Manager/
            res << server
          end
        end
        raise "FATAL: No Database Manager servers found" unless res.length > 0
        res
      end

      # lookup all the RightScripts that we will want to run
      def mysql_lookup_scripts
       scripts = [
                   [ 'setup_block_device',           'db::setup_block_device' ],
                   [ 'do_backup',                    'db::do_backup' ],
                   [ 'do_restore',                   'db::do_restore' ],
                   [ 'do_force_reset',               'db::do_force_reset' ],
                   [ 'setup_rule',                   'sys_firewall::setup_rule' ],
                   [ 'do_list_rules',                'sys_firewall::do_list_rules' ],
                   [ 'do_reconverge_list_enable',    'sys::do_reconverge_list_enable' ],
                   [ 'do_reconverge_list_disable',   'sys::do_reconverge_list_disable' ],
                   [ 'do_force_reset',               'db::do_force_reset' ],

                   [ 'do_init_slave',                'db_mysql::do_init_slave'], 
                   [ 'do_promote_to_master',         'db_mysql::do_promote_to_master'],
                   [ 'setup_master_dns',             'db_mysql::setup_master_dns'],
                   [ 'do_lookup_master',             'db_mysql::do_lookup_master.rb' ],
                   [ 'do_restore_and_become_master', 'db_mysql::do_restore_and_become_master.rb' ],
                   [ 'do_tag_as_master',             'db_mysql::do_tag_as_master.rb' ],
                   [ 'setup_master_backup',          'db_mysql::setup_master_backup.rb' ],
                   [ 'setup_replication_privileges', 'db_mysql::setup_replication_privileges.rb' ],
                   [ 'setup_slave_backup',           'db_mysql::setup_slave_backup.rb' ]
                 ]
        raise "FATAL: Need 1 MySQL servers in the deployment" unless mysql_servers.size >= 1
   
        st = ServerTemplate.find(resource_id(mysql_servers.first.server_template_href))
        load_script_table(st,scripts,st)
      end

      # Find all snapshots associated with this deployment's lineage
      def find_snapshots
        s = @servers.first
        unless @lineage
          kind_params = s.parameters
          @lineage = kind_params['db/backup/lineage'].gsub(/text:/, "")
        end
        if s.cloud_id.to_i < 10
          snapshots = Ec2EbsSnapshot.find_by_tags("rs_backup:lineage=#{@lineage}")
        elsif s.cloud_id.to_i == 232
          snapshots = [] # Ignore Rackspace, there are no snapshots
        else
          snapshots = McVolumeSnapshot.find_by_tags("rs_backup:lineage=#{@lineage}").select { |vs| vs.cloud.split(/\//).last.to_i == s.cloud_id.to_i }
        end
        snapshots
      end

      def find_snapshot_timestamp(server, provider = :volume)
        case provider
        when :volume
          if server.cloud_id.to_i != 232
            last_snap = find_snapshots.last
            last_snap.tags(true).detect { |t| t =~ /timestamp=(\d+)$/ }
            timestamp = $1
          else #Rackspace uses cloudfiles object store
            cloud_files = Fog::Storage.new(:provider => 'Rackspace')
            if dir = cloud_files.directories.detect { |d| d.key == @container }
              dir.files.first.key =~ /-([0-9]+\/[0-9]+)/
              timestamp = $1
            end
          end
        when "S3"
          s3 = Fog::Storage.new(:provider => 'AWS')
          if dir = s3.directories.detect { |d| d.key == @secondary_container }
            dir.files.first.key =~ /-([0-9]+\/[0-9]+)/
            timestamp = $1
          end
        when "CloudFiles"
          cloud_files = Fog::Storage.new(:provider => 'Rackspace')
          if dir = cloud_files.directories.detect { |d| d.key == @secondary_container }
            dir.files.first.key =~ /-([0-9]+\/[0-9]+)/
            timestamp = $1
          end
        else
          raise "FATAL: Provider #{provider.to_s} not supported."
        end
        return timestamp
      end

      def cleanup_snapshots
        find_snapshots.each do |snap|
          snap.destroy
        end
        # TODO cleanup secondary_container
      end

      def cleanup_volumes
        @servers.each do |server|
          unless ["stopped", "pending", "inactive", "decommissioning"].include?(server.state)
            run_script("do_force_reset", server)
          end
        end
      end

      def import_unified_app_sqldump
        load_script('import_dump', RightScript.new('href' => '/api/acct/2901/right_scripts/187123'))
        raise "Did not find script: import_dump" unless script_to_run?('import_dump')
        run_script_on_set('import_dump', mysql_servers, true, { 'DBAPPLICATION_PASSWORD' => 'cred:DBAPPLICATION_PASSWORD', 'DBAPPLICATION_USER' => 'cred:DBAPPLICATION_USER' })
      end

      # sets the lineage for the deployment
      # * kind<~String> can be "chef" or nil
      def set_variation_lineage()
        @lineage = "testlineage#{resource_id(@deployment)}"
        puts "Set variation LINEAGE: #{@lineage}"
        @deployment.set_input('db/backup/lineage', "text:#{@lineage}")
        @servers.each do |server|
          server.set_inputs({"db/backup/lineage" => "text:#{@lineage}"})
        end
      end
  
      def set_variation_container
        @container = "testlineage#{resource_id(@deployment)}"
        puts "Set variation CONTAINER: #{@container}"
        @deployment.set_input("block_device/storage_container", "text:#{@container}")
        @servers.each do |server|
          server.set_inputs({"block_device/storage_container" => "text:#{@container}"})
        end
      end
      
      # sets the storage provider for the server
      # * kind<~String> can be "chef" or nil
      def set_variation_storage_account_provider(provider)
        @deployment.set_input("db_mysql/dump/storage_account_provider", "text:#{provider}")
        @servers.each do |server|
          server.set_inputs({"db_mysql/dump/storage_account_provider" => "text:#{provider}"})
        end
        # Set the username and auth inputs for the account provider

        case provider
        when "ec2"
          @servers.each do |server|
            server.set_inputs({"block_device/storage_account_id" => "cred:AWS_ACCESS_KEY_ID"})
            server.set_inputs({"block_device/storage_account_secret" => "cred:AWS_SECRET_ACCESS_KEY"})
          end
        when "rackspace"
          @servers.each do |server|
            server.set_inputs({"block_device/storage_account_id" => "cred:RACKSPACE_USERNAME"})
            server.set_inputs({"block_device/storage_account_secret" => "cred:RACKSPACE_AUTH_KEY"})
          end
        else
          raise "FATAL: Provider #{provider.to_s} not supported."
        end
      end

      def test_primary_backup
        run_script("setup_block_device", s_one)
        probe(s_one, "touch /mnt/storage/monkey_was_here")
        run_script("do_backup", s_one)
        wait_for_snapshots
        run_script("do_force_reset", s_one)
        run_script("do_restore", s_one)
        probe(s_one, "ls /mnt/storage") do |result, status|
          raise "FATAL: no files found in the backup" if result == nil || result.empty?
          true
        end
        run_script("do_force_reset", s_one)
        run_script("do_restore", s_one, {"db/backup/timestamp_override" =>
                                         "text:#{find_snapshot_timestamp(s_one)}" })
        probe(s_one, "ls /mnt/storage") do |result, status|
          raise "FATAL: no files found in the backup" if result == nil || result.empty?
          true
        end
      end
  
      def set_secondary_backup_inputs(location="S3")
        @secondary_container = "testsecondary#{resource_id(@deployment)}"
        puts "Set secondary backup CONTAINER: #{@secondary_container}"
        @deployment.set_input("db/backup/secondary_container", "text:#{@secondary_container}")
        @servers.each do |server|
          server.set_inputs({"db/backup/secondary_container" => "text:#{@secondary_container}"})
        end
        location ||= "CloudFiles"
        puts "Set secondary backup LOCATION: #{location}"
        @deployment.set_input( "db/backup/secondary_location", "text:#{location}")
        @servers.each do |server|
          server.set_inputs({"db/backup/secondary_location" => "text:#{location}"})
        end
      end
  
      def test_secondary_backup(location="S3")
        cid = VirtualMonkey::Toolbox::determine_cloud_id(s_one)
        if cid == 232 && location == "CloudFiles"
          puts "Skipping secondary backup to cloudfiles on Rax -- this is already used for primary backup."
        else
          set_secondary_backup_inputs(location)
          run_script("setup_block_device", s_one)
          probe(s_one, "touch /mnt/storage/monkey_was_here")
          run_script("do_secondary_backup", s_one)
          wait_for_snapshots
          run_script("do_force_reset", s_one)
          run_script("do_secondary_restore", s_one)
          probe(s_one, "ls /mnt/storage") do |result, status|
            raise "FATAL: no files found in the backup" if result == nil || result.empty?
            true
          end
          run_script("do_force_reset", s_one)
          run_script("do_secondary_restore", s_one, { "db/backup/timestamp_override" =>
                                                      "text:#{find_snapshot_timestamp(s_one,location)}" })
          probe(s_one, "ls /mnt/storage") do |result, status|
            raise "FATAL: no files found in the backup" if result == nil || result.empty?
            true
          end
        end
      end

      def run_chef_promotion_operations
       config_master_from_scratch(s_one)
       check_master(s_one) ## check is the server sone is a master
        obj_behavior(s_one, :relaunch)
        s_one.dns_name = nil
        wait_for_snapshots
        # need to wait for ebs snapshot, otherwise this could easily fail
       restore_server(s_two)
       check_master(s_two) # check if s_two is now master
        obj_behavior(s_one, :wait_for_operational_with_dns)
       wait_for_snapshots
       
       slave_init_server(s_one)
       check_slave(s_one)
       check_master(s_two)
       
       promote_server(s_one)
        check_slave(s_two)
        check_master(s_one)
      end

      def run_chef_checks
        #TODO replicate the checks in the 11H1 tests.
        # check that mysql tmpdir is custom setup on all servers
          query = "show variables like 'tmpdir'"
          query_command = "echo -e \"#{query}\"| mysql"
          probe(@servers, query_command) { |result,st| result.include?("/mnt/mysqltmp") }
         
          # check that mysql cron script exits success
          @servers.each do |server|
            chk1 = probe(server, "/usr/local/bin/mysql-binary-backup.rb --if-master --max-snapshots 10 -D 4 -W 1 -M 1 -Y 1")
         
            chk2 = probe(server, "/usr/local/bin/mysql-binary-backup.rb --if-slave --max-snapshots 10 -D 4 -W 1 -M 1 -Y 1")
         
            raise "CRON BACKUPS FAILED TO EXEC, Aborting" unless (chk1 || chk2) 
          
            # check that logrotate has mysqlslow in it
            probe(@servers, "logrotate --force -v /etc/logrotate.d/mysql-server") { |out,st| out =~ /mysqlslow/ and st == 0 }
          end
     end

      def run_HA_reboot_operations
        #TODO replicate the checks in the 11H1 tests.
        # Duplicate code here because we need to wait between the master and the slave time
                @servers.each do |s|
                  obj_behavior(s, :reboot, true)
                  obj_behavior(s, :wait_for_state, "operational")
                end
               wait_for_all("operational")
               run_HA_reboot_checks
      end

      def run_HA_reboot_checks
         # one simple check we can do is the backup.  Backup can fail if anything is amiss
         @servers.each do |server|
         run_script("backup", server)
         end
      end
     
      def enable_db_reconverge
        run_script_on_set('do_reconverge_list_enable', mysql_servers)
      end

      def disable_db_reconverge
        run_script_on_set('do_reconverge_list_disable', mysql_servers)
      end

      # Runs a mysql query on specified server.
      # * query<~String> a SQL query string to execute
      # * server<~Server> the server to run the query on 
      def run_query(query, server, &block)
        query_command = "echo -e \"#{query}\"| mysql"
        probe(server, query_command, &block)
      end
  
      # Use the termination script to stop all the servers (this cleans up the volumes)
      def stop_all(wait=true)
        @servers.each { |s| s.stop }
  
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
     
      def setup_block_device
        puts "SETUP_BLOCK_DEVICE"
        run_script("setup_block_device", s_one)
      end
  
      def do_backup
        puts "BACKUP"
        run_script("do_backup", s_one)
      end
  
      def do_restore
        puts "RESTORE"
        run_script("do_restore", s_one)
      end
  
      def do_force_reset
        puts "RESET"
        run_script("do_force_reset", s_one)
      end
  
      # releases records back into the shared DNS pool
      def release_dns
        @dns.release_dns
      end
  
      def release_container
        set_variation_container
        ary = []
        raise "FATAL: could not cleanup because @container was '#{@container}'" unless @container
        s3 = Fog::Storage.new(:provider => 'AWS')
        ary << s3.directories.all.select {|d| d.key =~ /^#{@container}/}
        if Fog.credentials[:rackspace_username] and Fog.credentials[:rackspace_api_key]
          rax = Fog::Storage.new(:provider => 'Rackspace')
          ary << rax.directories.all.select {|d| d.key =~ /^#{@container}/}
        else
          puts "No Rackspace Credentials!"
        end
        ary.each do |con|
          con.each do |dir|
            dir.files.each do |file|
              file.destroy
            end
            dir.destroy
          end
        end
      end

      def create_monkey_table
        run_query("create database bananas", s_one)
        run_query("use bananas; create table bunches (tree text)", s_one)
        run_query("use bananas; insert into bunches values ('banana')", s_one)
      end

      def run_reboot_operations
        # set up a database to test after we reboot
        @engines = ['myisam', 'innodb']
        @servers.each do |server|
          run_query("create database monkey_database", server)
          @engines.each do |engine|
            run_query("use monkey_database; create table monkey_table_#{engine} (monkey_column text) engine = #{engine}; insert into monkey_table_#{engine} values ('Hello monkey!')", server)
          end
        end
        # Duplicate code here because we need to wait between the master and the slave time
        #reboot_all(true) # serially_reboot = true
        @servers.each do |s|
          s.reboot(true)
          s.wait_for_state("operational")
        end
        wait_for_all("operational")
        run_reboot_checks
      end
  
      # This is where we perform multiple checks on the deployment after a reboot.
      def run_reboot_checks
        # test that the data we created is still there after the reboot
        @servers.each do |server|
          @engines.each do |engine|
            run_query("use monkey_database; select monkey_column from monkey_table_#{engine}", server) do |result, status|
              raise "Database reboot failed, data is missing: #{result}" unless result =~ /Hello monkey!/
              true
            end
          end
        end
        # one simple check we can do is the backup.  Backup can fail if anything is amiss
        @servers.each do |server|
          run_script("do_backup", server)
        end
      end
  
  #    def run_restore_with_timestamp_override
  #      obj_behavior(s_one, :relaunch)
  #      s_one.dns_name = nil
  #      obj_behavior(s_one, :wait_for_operational_with_dns)
  #     run_script('restore', s_one, { "OPT_DB_RESTORE_TIMESTAMP_OVERRIDE" => "text:#{find_snapshot_timestamp}" })
  #    end
  
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
          transaction {
            #mysql commands to generate data for collectd to return
            50.times do |ii|
              query = <<EOS
show databases; 
create database test#{ii};
use test#{ii};
create table test#{ii}(test text);
show tables;
insert into test#{ii} values ('1');
update test#{ii} set test='2';
select * from test#{ii};
delete from test#{ii};
show variables;
show status;
grant select on test.* to root;
alter table test#{ii} rename to test2#{ii};
EOS
              run_query(query, server)
            end
            mysql_plugins.each do |plugin|
              monitor = server.get_sketchy_data({ 'start' => -60,
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
          }
        end
      end
  
      def set_variation_dnschoice(dns_choice)
        @deployment.set_input("sys_dns/choice", "#{dns_choice}")
      end
      
      def set_variation_http_only
        @deployment.set_input("web_apache/ssl_enable", "text:false")
      end

      def config_master_from_scratch(server)
       create_stripe(server)
        probe(server, "service mysqld start") # TODO Check that it started?
        #TODO the service name depends on the OS
        #      server.spot_check_command("service mysql start")
       run_query("create database mynewtest", server)
       set_master_dns(server)
        # This sleep is to wait for DNS to settle - must sleep
        sleep 120
        run_script("do_backup", server)
      end
 
      def slave_init_server(server)
        run_script("do_init_slave", server)
      end
      
      def restore_server(server)
        run_script("do_restore ", server)
      end
      
      def promote_server(server)
        run_script("do_promote_to_master", server)
      end
      
      def set_master_dns(server)
        run_script('setup_master_dns', server)
      end
      
      # checks if the server is infact a master
      def check_master(master_server)
        count_num_master_tags = 0  # this number should equal 2 otherwise it is not valid
        master_server.settings
        master_server.reload
        
        # get all the tags and then do a regex
        Tag.search_by_href(master_server.current_instance_href).each{ |hash_output|
          hash_output.each{ |key, value|
            if value.to_s.match(/master_active/)  
              count_num_master_tags+=1
            elsif value.to_s.match(/master_instance_uuid/)
              count_num_master_tags+=1
            end
           }     
        }
        raise "Less than 2 master tags found on #{master_server.current_instance_href}" unless (count_num_master_tags == 2)          
      end
      
      # checks if the server is infact a slave
      def check_slave(slave_server)
              count_num_slave_tags = 0  # this number should equal 2 otherwise it is not valid
              slave_server.settings
              slave_server.reload
              
              # get all the tags and then do a regex
              Tag.search_by_href(slave_server.current_instance_href).each{ |hash_output|
                hash_output.each{ |key, value|
                  if value.to_s.match(/slave_active/)  
                    count_num_slave_tags+=1
                  elsif value.to_s.match(/slave_instance_uuid/)
                    count_num_slave_tags+=1
                  end
                 }     
              }
              raise "Less than 2 slave tags found on #{slave_server.current_instance_href}" unless (count_num_slave_tags == 2)          
       end
       
      # creates a MySQL enabled EBS stripe on the server
      # * server<~Server> the server to create stripe on
      def create_stripe(server)
        options = { "block_device/volume_size" => "text:1", 
                    "db/application/user" => "text:someuser", 
                    "block_device/aws_access_key_id" => "ignore:$ignore",
                    "block_device/aws_secret_access_key" => "ignore:$ignore",
                    "db/application/password" => "text:somepass", 
                    "block_device/volume_size" => "text:1",
                    "db/backup/lineage" => "text:#{@lineage}" }
        run_script('setup_block_device', server, options) 
      end
      
    end
  end
end