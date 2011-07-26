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

          obj_behavior(fe_servers.first, :reboot, true)
          obj_behavior(fe_servers.first, :wait_for_state, "operational")
	
          obj_behavior(app_servers.first, :reboot, true)
          obj_behavior(app_servers.first, :wait_for_state, "operational")
        
       wait_for_all("operational")
       run_reboot_checks
      end
  
      def run_reboot_checks
       run_unified_application_checks(fe_servers, 443)
       #run_unified_application_checks(app_servers, 80)
      end

    end
  end
end
