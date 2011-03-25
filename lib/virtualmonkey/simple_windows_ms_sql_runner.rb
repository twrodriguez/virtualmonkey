module VirtualMonkey
  class SimpleWindowsSQLRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::Simple
    def exception_handle(e)
      puts "ATTENTION: Using default exception_handle(e). This can be overridden in mixin classes."
      puts "Got this \"#{e.message}\"."
      if e.message =~ /timed out waiting for the state to be operational/
        puts "Got \"#{e.message}\". Retrying...."
        sleep 60
      elsif e.message =~ /this server is stranded and needs to be operational/
        puts "Got \"#{e.message}\". Retrying...."
        sleep 60
      else
        raise e
      end
    end
    def lookup_scripts
     scripts = [
                 [ 'SYS EBS create data volume', 'SYS EBS create data volume' ],
                 [ 'DB SQLS backup data volume', 'DB SQLS backup data volume' ],
                 [ 'DB SQLS restore data volume', 'DB SQLS restore data volume' ],
               ]
      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      lookup_scripts_table(st,scripts)
      add_script_to_run('sql_db_check', RightScript.new('href' => "/api/acct/2901/right_scripts/335104"))
      add_script_to_run('load_db', RightScript.new('href' => "/api/acct/2901/right_scripts/331394"))
    end
  end
end
