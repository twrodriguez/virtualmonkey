module VirtualMonkey
  class SimpleWindowsSQLRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::SimpleWindows

    def simple_windows_sql_lookup_scripts
     scripts = [
                 [ 'SYS EBS create data volume', 'SYS EBS create data volume' ],
                 [ 'DB SQLS backup data volume', 'DB SQLS backup data volume' ],
                 [ 'DB SQLS restore data volume', 'DB SQLS restore data volume' ],
               ]
      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      load_script_table(st,scripts)
      load_script('sql_db_check', RightScript.new('href' => "/api/acct/2901/right_scripts/335104"))
      load_script('load_db', RightScript.new('href' => "/api/acct/2901/right_scripts/331394"))
    end
  end
end
