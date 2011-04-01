module VirtualMonkey
  class PostgresRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    include VirtualMonkey::Postgres
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

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
     scripts = [
                 [ 'backup', 'EBS PostgreSQL backup' ],
                 [ 'create_stripe' , 'Create PostgreSQL EBS stripe volume' ],
                 [ 'dump_import', 'PostgreSQL dump import'],
                 [ 'dump_export', 'PostgreSQL dump export'],
                 [ 'freeze_backups', 'DB PostgreSQL Freeze' ],
                 [ 'restore', 'PostgreSQL restore and become' ],
                 [ 'terminate', 'PostgreSQL TERMINATE SERVER' ],
                 [ 'unfreeze_backups', 'DB PostgreSQL Unfreeze' ]
               ]

      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      lookup_scripts_table(st,scripts)
      # hardwired script! (this is an 'anyscript' that users typically use to setup the master dns)
      # This a special version of the register that uses MASTER_DB_DNSID instead of a test DNSID
      # This is identical to "DB register master" However it is not part of the template.
      add_script_to_run('master_init', RightScript.new('href' => "/api/acct/2901/right_scripts/195053"))
      raise "Did not find script" unless script_to_run?('master_init')
    end

    def run_restore_with_timestamp_override
      object_behavior(s_one, :relaunch)
      s_one.dns_name = nil
      object_behavior(s_one, :wait_for_operational_with_dns)
      behavior(:run_script, 'restore', s_one, { "OPT_DB_RESTORE_TIMESTAMP_OVERRIDE" => "text:#{find_snapshot_timestamp}" })
    end
  end
end
