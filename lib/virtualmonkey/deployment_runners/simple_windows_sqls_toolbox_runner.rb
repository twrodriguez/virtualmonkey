module VirtualMonkey
  module Runner
    class SimpleWindowsSqlsToolbox
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows

      description "TODO"

      def set_test_lineage
        @lineage = "monkey_ms_sql_testlineage#{resource_id(@deployment)}"
        @deployment.set_input("DB_LINEAGE_NAME", "text:#{@lineage}")
        s_one.set_inputs({"DB_LINEAGE_NAME" => "text:#{@lineage}"})
        @prefix = "#{resource_id(@deployment)}"
        @deployment.set_input("OPT_FILE_PREFIX", "text:#{@prefix}")
        s_one.set_inputs({"OPT_FILE_PREFIX" => "text:#{@prefix}"})
      end

      def vitaly_windows_sqls_toolbox_lookup_scripts
        scripts = [
                    [ 'EBS Create Data and Log volumes', 'EBS Create Data and Log volumes' ],
                    [ 'EBS Create Backup volume', 'EBS Create Backup volume' ],
                    [ 'DB SQLS Configure TempDB', 'DB SQLS Configure TempDB' ],
                    [ 'DB SQLS Restore from disk/S3', 'DB SQLS Restore from disk/S3' ],
                    [ 'DB SQLS Set Full Recovery Model', 'DB SQLS Set Full Recovery Model' ],
                    [ 'DB SQLS Set default backup compression', 'DB SQLS Set default backup compression' ],
                    [ 'DB SQLS Create login', 'DB SQLS Create login' ],
                    [ 'DB SQLS Switch mirroring off', 'DB SQLS Switch mirroring off' ],
                    [ 'DB SQLS Backup to disk/S3', 'DB SQLS Backup to disk/S3' ],
                    [ 'DB SQLS Norecovery snapshot', 'DB SQLS Norecovery snapshot' ],
                    [ 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes', 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes' ]
                  ]
        st = @server_templates.detect{ |st| st.nickname =~ /Microsoft SQL Server Toolbox/i }
        load_script_table(st,scripts)
        load_script('SQLS CHECK volumes created', RightScript.new('href' => "/api/acct/2901/right_scripts/434990"))
        load_script('SQLS CHECK backup volume created', RightScript.new('href' => "/api/acct/2901/right_scripts/435042"))
        load_script('SQLS CHECK tempdb configured', RightScript.new('href' => "/api/acct/2901/right_scripts/435046"))
        load_script('SQLS CHECK restore from disk/S3 ok', RightScript.new('href' => "/api/acct/2901/right_scripts/435047"))
        load_script('SQLS CHECK full recovery model set', RightScript.new('href' => "/api/acct/2901/right_scripts/435071"))
        load_script('SQLS CHECK backup compression set', RightScript.new('href' => "/api/acct/2901/right_scripts/435073"))
        load_script('SQLS CHECK login created', RightScript.new('href' => "/api/acct/2901/right_scripts/435075"))
        load_script('SQLS CHECK mirroring switched off', RightScript.new('href' => "/api/acct/2901/right_scripts/435045"))
        load_script('SQLS CHECK backup to disk/S3 ok', RightScript.new('href' => "/api/acct/2901/right_scripts/435096"))
        load_script('SQLS CHECK norecovery snapshot ok', RightScript.new('href' => "/api/acct/2901/right_scripts/435097"))
      end
    end
  end
end
