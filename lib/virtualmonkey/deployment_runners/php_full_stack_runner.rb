module VirtualMonkey
  module Runner
    class PhpChef
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
      include VirtualMonkey::Mixin::UnifiedApplication
      include VirtualMonkey::Mixin::Frontend
      include VirtualMonkey::Mixin::Chef
      include VirtualMonkey::Mixin::PhpChef
      include VirtualMonkey::Mixin::ChefMysql


      
      def run_reboot_operations
       # reboot front_end and wait for operational
       # reboot app_server and wait for operational
       # then do the reboot checks

          
  #       transaction { mysql_servers.first.reboot( true)}
   #      transaction {mysql_servers.first.wait_for_state( "operational") }
         
         transaction { fe_servers[0].reboot( true)}
         transaction { fe_servers[0].wait_for_state( "operational")}
         
         transaction { fe_servers[1].reboot( true)}
         transaction { fe_servers[1].wait_for_state( "operational")}
         
         transaction {app_servers[0].reboot( true) }
         transaction {app_servers[0].wait_for_state( "operational") }
         
         transaction {app_servers[1].reboot( true) }
         transaction {app_servers[1].wait_for_state( "operational") }
        #end
       wait_for_all("operational")
       run_reboot_checks
      end
  
      def run_reboot_checks
       run_unified_application_checks(fe_servers, 443)
       run_unified_application_checks(fe_servers, 80)
      end

    end
  end
end
