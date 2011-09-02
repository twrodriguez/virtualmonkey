module VirtualMonkey
  module Runner
    class SimpleWindowsSqlsMirroring
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows

      def principal_mirror_server
        mirror_servers.detect { |s| s.get_info_tags['self']['principal'] == 'true' }
      end

      def secondary_mirror_server
        mirror_servers.detect { |s| s.get_info_tags['self']['secondary'] == 'true' }
      end
 
      def mirror_servers
        st = ServerTemplate.find_by(:nickname) { |n| n =~ /Microsoft SQL Server HA - Mirroring/i } 
        match_servers_by_st(st[0])
      end

      def toolbox_server
        st = ServerTemplate.find_by(:nickname) { |n| n =~ /Microsoft SQL Server Toolbox/i }
        match_servers_by_st(st[0])
      end

      def set_mirroring_inputs
        @lineage = "monkey_ms_sql_testlineage#{resource_id(@deployment)}"
        @deployment.set_input("DB_LINEAGE_NAME", "text:#{@lineage}")
        s_one.set_inputs({"DB_LINEAGE_NAME" => "text:#{@lineage}"})
        @prefix = "#{resource_id(@deployment)}"
        @deployment.set_input("OPT_FILE_PREFIX", "text:#{@prefix}")
        s_one.set_inputs({"OPT_FILE_PREFIX" => "text:#{@prefix}"})

        m_servers = mirror_servers
        m_servers[0].set_inputs({"MIRRORING_ROLE" => "text:Principal"})
        m_servers[0].set_info_tags('principal' => 'true')

        m_servers[1].set_inputs({"MIRRORING_ROLE" => "text:Mirror"})
        m_servers[1].set_info_tags('secondary' => 'true')
      end
      
      def vitaly_windows_sqls_toolbox_lookup_scripts
        scripts = [
                    [ 'DNS dnsmadeeasy register IP', 'DNS dnsmadeeasy register IP' ],
                    [ 'DB SQLS Manual failover', 'DB SQLS Manual failover' ],
                    [ 'DB SQLS Switch mirroring off', 'DB SQLS Switch mirroring off' ]
                  ]
        st = ServerTemplate.find_by(:nickname) { |n| n =~ /Microsoft SQL Server HA - Mirroring/i } 
        load_script_table(st[0],scripts)
        load_script('SQLS CHECK principal connected', RightScript.new('href' => "/api/acct/29082/right_scripts/432516"))
        load_script('SQLS CHECK dns updated', RightScript.new('href' => "/api/acct/29082/right_scripts/432517"))
        load_script('SQLS CHECK failover ok', RightScript.new('href' => "/api/acct/29082/right_scripts/432518"))
        load_script('SQLS CHECK mirroring switched off', RightScript.new('href' => "/api/acct/29082/right_scripts/431570"))

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
                    [ 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes v1', 'DB SQLS DISABLE SERVER - snapshot, detach and delete volumes v1' ]
                  ]
        st = ServerTemplate.find_by(:nickname) { |n| n =~ /Microsoft SQL Server Toolbox/i }
        load_script_table(st[0],scripts)
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
