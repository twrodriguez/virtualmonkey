module VirtualMonkey
  module Mixin
    module SimpleWindowsSQL
      extend VirtualMonkey::Mixin::CommandHooks
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
        st = match_st_by_server(s_one)
        load_script_table(st,scripts)
        load_script('sql_db_check', RightScript.new('href' => "/api/acct/2901/right_scripts/335104"))
        load_script('load_db', RightScript.new('href' => "/api/acct/2901/right_scripts/331394"))
        load_script('tempdb_check', RightScript.new('href' => "/api/acct/2901/right_scripts/381500"))
        load_script('newuser_check', RightScript.new('href' => "/api/acct/2901/right_scripts/381571"))
        load_script('log_repair_before', RightScript.new('href' => "/api/acct/2901/right_scripts/381785"))
        load_script('log_repair_after', RightScript.new('href' => "/api/acct/2901/right_scripts/382117"))
        load_script('new_name_check', RightScript.new('href' => "/api/acct/2901/right_scripts/382185"))
      end

      def set_test_lineage
        @lineage = "monkey_ms_sql_testlineage#{resource_id(@deployment)}"
        @deployment.set_input("DB_LINEAGE_NAME", "text:#{@lineage}")
        s_one.set_inputs({"DB_LINEAGE_NAME" => "text:#{@lineage}"})
      end

      # Find all snapshots associated with this deployment's lineage
      def find_snapshots
        s = @servers.first
        unless @lineage
          kind_params = s.parameters
          @lineage = kind_params['DB_LINEAGE_NAME'].gsub(/text:/, "")
        end
        if s.cloud_id.to_i < 10
          snapshots = Ec2EbsSnapshot.find_by_tags("rs_backup:lineage=#{@lineage}")
        elsif s.cloud_id.to_i == 232
          snapshot = [] # Ignore Rackspace, there are no snapshots
        else
          snapshots = McVolumeSnapshot.find_by_tags("rs_backup:lineage=#{@lineage}").select { |vs| vs.cloud.split(/\//).last.to_i == s.cloud_id.to_i }
        end
        snapshots
      end

      def cleanup_volumes
        @servers.each do |server|
          unless ["stopped", "pending", "inactive", "decommissioning"].include?(server.state)
            run_script('DB SQLS DISABLE SERVER - snapshot, detach and delete volumes', server)
          end
        end
      end

      def cleanup_snapshots
        find_snapshots.each do |snap|
          snap.destroy
        end
      end

    end
  end
end
