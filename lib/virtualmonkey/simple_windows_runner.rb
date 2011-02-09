module VirtualMonkey
  class SimpleWindowsRunner
    include VirtualMonkey::DeploymentRunner
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
                 [ 'backup_database', 'backup_database' ],
                 [ 'drop_database', 'drop_database' ],
                 [ 'restore_database', 'restore_database' ],
               ]
      st = ServerTemplate.find(s_one.server_template_href.split(/\//).last.to_i)
      lookup_scripts_table(st,scripts)
      @scripts_to_run['backup_database_check'] = RightScript.new('href' => "/api/acct/2901/right_scripts/310407")
    end
  end
end

