module VirtualMonkey
  class MysqlRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    include VirtualMonkey::Mysql
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

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
      behavior(:wait_for_snapshots)
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


    # lookup all the RightScripts that we will want to run
    def lookup_scripts
#TODO fix this so epoch is not hard coded.
puts "WE ARE HARDCODING THE TOOL BOX NAMES TO USE 11H1.b1"
     scripts = [
                 [ 'restore', 'restore and become' ],
                 [ 'slave_init', 'slave init' ],
                 [ 'promote', 'EBS promote to master' ],
                 [ 'backup', 'EBS backup' ],
                 [ 'terminate', 'TERMINATE SERVER' ],
                 [ 'freeze_backups', 'DB freeze' ]
               ]
      ebs_toolbox_scripts = [
                              [ 'create_stripe' , 'EBS stripe volume create - 11H1' ]
                            ]
      mysql_toolbox_scripts = [
                              [ 'create_mysql_ebs_stripe' , 'DB Create MySQL EBS stripe volume - 11H1' ],
                              [ 'create_migrate_script' , 'DB EBS create migrate script from MySQL EBS v1' ]
                            ]
      st = ServerTemplate.find(s_two.server_template_href.split(/\//).last.to_i)
      lookup_scripts_table(st,scripts)
      @scripts_to_run['master_init'] = RightScript.new('href' => "/api/acct/2901/right_scripts/195053")
      #This does not work - does not create the same type as call above does.
      #@scripts_to_run['master_init'] = RightScript.find_by("name") { |n| n =~ /DB register master \-ONLY FOR TESTING/ }
      raise "Did not find script" unless @scripts_to_run['master_init']

      tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /EBS Stripe Toolbox - 11H1.b1/ }
      raise "Did not find toolbox template" unless tbx[0]
      # Use the HEAD revision.
      lookup_scripts_table(tbx[0],ebs_toolbox_scripts)
#      @scripts_to_run['create_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/198381")
#TODO - does not account for 5.0/5.1 toolbox differences
      #tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /Database Manager with MySQL 5.0 Toolbox - 11H1.b1/ }
      #use_tbx = tbx.detect { |t| t.is_head_version }
      use_tbx = ServerTemplate.find 84657
      raise "Did not find toolbox template" unless use_tbx
      puts "USING Toolbox Template: #{use_tbx.nickname}"
      lookup_scripts_table(use_tbx,mysql_toolbox_scripts)
#      @scripts_to_run['create_mysql_ebs_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/212492")
#      @scripts_to_run['create_migrate_script'] = tbx[0].executables.detect { |ex| ex.name =~ /DB EBS create migrate script from MySQL EBS v1 master/ }
     raise "FATAL: Need 2 MySQL servers in the deployment" unless @servers.size == 2
    end

    def migrate_slave
      s_one.settings
      object_behavior(s_one, :spot_check_command, "/tmp/init_slave.sh")
      behavior(:run_script, "backup", s_one)
    end
   
    def launch_v2_slave
      s_two.settings
      behavior(:wait_for_snapshots)
      behavior(:run_script, "slave_init", s_two)
    end

    def run_restore_with_timestamp_override
      object_behavior(s_one, :relaunch)
      s_one.dns_name = nil
      s_one.wait_for_operational_with_dns
      audit = object_behavior(s_one, :run_executable, @scripts_to_run['restore'], { "OPT_DB_RESTORE_TIMESTAMP_OVERRIDE" => "text:#{find_snapshot_timestamp}" } )
      audit.wait_for_completed
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
  end
end
