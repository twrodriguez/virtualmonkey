module VirtualMonkey
  module Runner
    class MysqlChefHA
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ChefEBS
      include VirtualMonkey::Mixin::ChefMysqlHA
      include VirtualMonkey::Mixin::Chef
      attr_accessor :scripts_to_run
      attr_accessor :db_ebs_prefix
  
      # pass in the instance server on which we want to check the backup on
      def wait_for_snapshots(server)
        done = false
        timeout=1500
        step=10
        while (timeout > 0 && !done)
          probe(server, "test -e /var/run/db-backup") { |response,status|
            done = true unless (status == 0)
            sleep step
            timeout -= step
         }
        end

         if(server.cloud_id <= 5)
           while timeout > 0
              timeout=1500
              step=10
              snapshots =find_snapshots
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
