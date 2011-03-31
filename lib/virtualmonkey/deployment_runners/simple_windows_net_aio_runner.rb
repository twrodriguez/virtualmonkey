module VirtualMonkey
  class SimpleWindowsNetRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::Simple
    def exception_handle(e)
      puts "ATTENTION: Using default exception_handle(e). This can be overridden in mixin classes."
      puts "Got this \"#{e.message}\"."
      if e.message =~ /timed out waiting for the state to be operational/
        puts "Got \"#{e.message}\". Retrying...."
        sleep 60
      else
        raise e
      end
    end
    def lookup_scripts
     scripts = [
                 [ 'backup', 'backup' ],
                 [ 'restore', 'restore' ],
                 [ 'backup_to_s3', 'backup_to_s3' ],
                 [ 'create_scheduled_task', 'create_scheduled_task' ],
                 [ 'delete_scheduled_task', 'delete_scheduled_task' ],
                 [ 'register_with_elb', 'register_with_elb' ],
                 [ 'deregister_from_elb', 'deregister_from_elb' ],
                 [ 'update_code_svn', 'update_code_svn' ]
               ]
      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      lookup_scripts_table(st,scripts)
      add_script_to_run('backup_database_check', RightScript.new('href' => "/api/acct/2901/right_scripts/310407"))
      raise "Did not find script" unless script_to_run?('backup_database_check')
    end
  end
end
