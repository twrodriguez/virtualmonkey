module VirtualMonkey
  module Runner
    class SimpleWindowsSqlsMirroring
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows

      description "TODO"

      def principal_mirror_server
        mirror_servers.detect { |s| s.get_info_tags['self']['principal'] == 'true' }
      end

      def secondary_mirror_server
        mirror_servers.detect { |s| s.get_info_tags['self']['secondary'] == 'true' }
      end

      def mirror_servers
        st = @server_templates.detect{ |st| st.nickname =~ /Microsoft SQL Server HA/i }
        match_servers_by_st(st)
      end

      def toolbox_server
        st = @server_templates.detect{ |st| st.nickname =~ /Microsoft SQL Server Toolbox/i }
        match_servers_by_st(st)
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
                    [ 'DNS DNSMadeEasy register IP', 'DNS DNSMadeEasy register IP' ],
                    [ 'DB SQLS Manual failover', 'DB SQLS Manual failover' ],
                    [ 'DB SQLS Switch mirroring off', 'DB SQLS Switch mirroring off' ]
                  ]
        st = @server_templates.detect{ |st| st.nickname =~ /Microsoft SQL Server HA/i }
        load_script_table(st,scripts)
        load_script('SQLS CHECK principal connected', RightScript.new('href' => "/api/acct/2901/right_scripts/434994"))
        load_script('SQLS CHECK dns updated', RightScript.new('href' => "/api/acct/2901/right_scripts/435041"))
        load_script('SQLS CHECK failover ok', RightScript.new('href' => "/api/acct/2901/right_scripts/435043"))
        load_script('SQLS CHECK mirroring switched off', RightScript.new('href' => "/api/acct/2901/right_scripts/435045"))

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
