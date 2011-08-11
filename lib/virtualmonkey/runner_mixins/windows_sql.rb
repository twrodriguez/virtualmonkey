module VirtualMonkey
  module Mixin
    module SimpleWindowsSQL 
      # Every instance method included in the runner class that has
      # "lookup_scripts" in its name is called when the Class is instantiated.
      # These functions help to create a hash table of RightScripts and/or
      # Chef Recipes that can be called on a given Server in the deployment.
      # By default, the functions that are used to create this hash table
      # allow every referenced Executable to be run on every server in the
      # deployment, but they can be restricted to only certain ServerTemplates
      # in the deployment.
      def SimpleWindowsSQL_lookup_scripts
        scripts = [
                   [ 'EBS Restore data and log volumes', 'EBS Restore data and log volumes' ],
                   [ 'EBS Create data and log volumes', 'EBS Create data and log volumes' ],
                   [ 'DB SQLS Configure tempdb', 'DB SQLS Configure tempdb' ],
                   [ 'EBS Backup data and log volumes', 'EBS Backup data and log volumes' ],
                   [ 'DB SQLS Rename instance', 'DB SQLS Rename instance' ],
                   [ 'DB SQLS create user', 'DB SQLS create user' ],
                   [ 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes', 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes' ],
                   [ 'DB SQLS Repair log files', 'DB SQLS Repair log files' ],
                 ]
        st = ServerTemplate.find(112763)
        load_script_table(st,scripts)
        load_script('sql_db_check', RightScript.new('href' => "/api/acct/2901/right_scripts/335104"))
        load_script('load_db', RightScript.new('href' => "/api/acct/2901/right_scripts/331394"))
        load_script('tempdb_check', RightScript.new('href' => "/api/acct/2901/right_scripts/381500"))
        load_script('newuser_check', RightScript.new('href' => "/api/acct/2901/right_scripts/381571"))
        load_script('log_repair_before', RightScript.new('href' => "/api/acct/2901/right_scripts/381785"))
        load_script('log_repair_after', RightScript.new('href' => "/api/acct/2901/right_scripts/382117"))
        load_script('new_name_check', RightScript.new('href' => "/api/acct/2901/right_scripts/382185"))
      end

    end
  end
end
