module VirtualMonkey
  module Mixin
    module Wishbone
      # Every instance method included in the runner class that has
      # "lookup_scripts" in its name is called when the Class is instantiated.
      # These functions help to create a hash table of RightScripts and/or
      # Chef Recipes that can be called on a given Server in the deployment.
      # By default, the functions that are used to create this hash table
      # allow every referenced Executable to be run on every server in the
      # deployment, but they can be restricted to only certain ServerTemplates
# inn the deployment.
     
=begin
      def wishbone_exception_handle
        if e.message =~ /INSERT YOUR ERROR HERE/
          puts "Got 'INSERT YOUR ERROR HERE'. Retrying..."
          sleep 30
          return true # Exception Handled
        else
          return false # Exception Not Handled
        end
      end
=end

      def wishbone_whitelist
        [
          #["/var/log/messages", "Load Balancer (Chef) - Alpha", "harmless"],
          #["/var/log/messages", "Database Manager for MySQL 5.1 (Chef) - Alpha", "ignore"]
        ]
      end

      def wishbone_blacklist
        [
          #["/var/log/messages", "Load Balancer (Chef) - Alpha", "exception"],
          #["/var/log/messages", "Database Manager for MySQL 5.1 (Chef) - Alpha", "error"]
        ]
      end

      def wishbone_needlist
        [
          #["/var/log/messages", "Load Balancer (Chef) - Alpha", "this should be here"],
          #["/var/log/messages", "Database Manager for MySQL 5.1 (Chef) - Alpha", "required line"]
        ]
      end



      def check_monitoring_exec_apache_ps
        probe(fe_servers, "ps ax | grep 'ruby .*/plugins/apache_ps -h ' | grep -v grep") do |result, status|
          raise "Configuring apache_ps collectd exec plugin failed, no process running" if result.empty?
          true
        end
      end

      def check_monitoring_exec_haproxy
        probe(fe_servers, "ps ax | grep 'ruby .*/plugins/haproxy -d .* -s /home/haproxy/status 10' | grep -v grep") do |result, status|
          raise "Configuring haproxy collectd exec plugin failed, no process running" if result.empty?
          true
        end
      end

      def run_reboot_operations
  # Duplicate code here because we need to wait between the master and the slave time
        #reboot_all(true) # serially_reboot = true
       # @servers.each do |s|
         transaction { mysql_servers.first.reboot( true)}
         transaction {mysql_servers.first.wait_for_state( "operational") }
         
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
  
      # This is where we perform multiple checks on the deployment after a reboot.
      def run_reboot_checks
        # one simple check we can do is the backup.  Backup can fail if anything is amiss
       sleep(60)
       run_unified_application_checks(fe_servers, 80)
        recipes = [
                    [ 'iptable_rules', 'sys_firewall::do_list_rules' ]
                  ]
        mysql_st = ServerTemplate.find(resource_id(mysql_servers.first.server_template_href))
        load_script_table(mysql_st,recipes)
        
       run_script_on_set('iptable_rules', mysql_servers.first)

       run_script("do_backup", mysql_servers.first)
       sleep(120)
       run_unified_application_checks(fe_servers, 80)
      end

      def setup_block_device
        run_script("setup_block_device", mysql_servers.first)
      end
    end
  end
end
