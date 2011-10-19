module VirtualMonkey
  module Runner
    class MysqlChefHA
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ChefEBS
      include VirtualMonkey::Mixin::ChefMysqlHA
      include VirtualMonkey::Mixin::Chef
      attr_accessor :scripts_to_run
      attr_accessor :db_ebs_prefix

      description "TODO"

      # pass in the instance server on which we want to check the backup on
      def wait_for_snapshots(server)
        done = false
        timeout=600 # 10  minutes is long engouh for our tests
        step=10
        while (timeout > 0 && !done)
          probe(server, "test -e /var/run/db-backup") { |response,status|
            done = true if (status == 0)
            sleep step
            timeout -= step
         }
        end

         if(server.cloud_id <= 5)
           while timeout > 0
              timeout=300
              step=10
              snapshots = find_snapshots(server)
              status = snapshots.map { |x| x.aws_status }
              break unless status.include?("pending")
              sleep step
              timeout -= step
          end
        end
        raise "FATAL: timed out waiting for all snapshots in lineage #{@lineage} to complete" if timeout <= 0
      end
    end
  end
end
