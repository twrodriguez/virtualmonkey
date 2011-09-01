module VirtualMonkey
  module Runner
    class SimpleWindowsSqlsToolbox
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows
  
      def vitaly_windows_sqls_toolbox_lookup_scripts
       scripts = [
                   [ 'EBS Create data and log volumes v1', 'EBS Create data and log volumes v1' ],
                   [ 'EBS Create backup volume', 'EBS Create backup volume' ],
                   [ 'DB SQLS Configure tempdb', 'DB SQLS Configure tempdb' ],
                   [ 'DB SQLS Restore from disk/S3 v1', 'DB SQLS Restore from disk/S3 v1' ],
                   [ 'DB SQLS Set Full Recovery Model', 'DB SQLS Set Full Recovery Model' ],
                   [ 'DB SQLS Set default backup compression', 'DB SQLS Set default backup compression' ],
                   [ 'DB SQLS Create login v1', 'DB SQLS Create login v1' ],
                   [ 'DB SQLS Switch mirroring off', 'DB SQLS Switch mirroring off' ],
                   [ 'DB SQLS Backup to disk/S3 v1', 'DB SQLS Backup to disk/S3 v1' ],
                   [ 'DB SQLS Norecovery snapshot', 'DB SQLS Norecovery snapshot' ],
                   [ 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes', 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes' ],
                 ]
        st = ServerTemplate.find(resource_id(s_one.server_template_href)) 
        load_script_table(st,scripts)
        load_script('SQLS CHECK volumes created', RightScript.new('href' => "/api/acct/29082/right_scripts/431561"))
        load_script('SQLS CHECK backup volume created', RightScript.new('href' => "/api/acct/29082/right_scripts/431567"))
        load_script('SQLS CHECK tempdb configured', RightScript.new('href' => "/api/acct/29082/right_scripts/431562"))
        load_script('SQLS CHECK restore from disk/S3 ok', RightScript.new('href' => "/api/acct/29082/right_scripts/431564"))
        load_script('SQLS CHECK full recovery model set', RightScript.new('href' => "/api/acct/29082/right_scripts/431566"))
        load_script('SQLS CHECK backup compression set', RightScript.new('href' => "/api/acct/29082/right_scripts/431569"))
        load_script('SQLS CHECK login created', RightScript.new('href' => "/api/acct/29082/right_scripts/431571"))
        load_script('SQLS CHECK mirroring switched off', RightScript.new('href' => "/api/acct/29082/right_scripts/431570"))
        load_script('SQLS CHECK backup to disk/S3 ok', RightScript.new('href' => "/api/acct/29082/right_scripts/431563"))
        load_script('SQLS CHECK norecovery snapshot ok', RightScript.new('href' => "/api/acct/29082/right_scripts/431568"))
      end
    end
  end
end
