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
=begin      def wishbone_lookup_scripts
        ###########################################################
        # Load Scripts from 'Load Balancer (Chef) - Alpha' [HEAD] #
        ###########################################################
        scripts = [
                   ['script_1', 'lb_haproxy::do_attach_all'],
                   ['script_2', 'lb_haproxy::handle_attach'],
                   ['script_3', 'lb_haproxy::handle_detach'],
                   ['script_4', 'sys_firewall::setup_rule'],
                   ['script_5', 'sys::do_reconverge_list_enable'],
                   ['script_6', 'sys::do_reconverge_list_disable']
                  ]
        st_ref = @server_templates.detect { |st| st.rs_id.to_i == 120077 }
        load_script_table(st_ref,scripts,st_ref)

        ############################################################
        # Load Scripts from 'PHP App Server (Chef) - Alpha' [HEAD] #
        ############################################################
        scripts = [
                   ['script_7', 'app_php::do_update_code'],
                   ['script_8', 'lb_haproxy::do_attach_request'],
                   ['script_9', 'lb_haproxy::do_detach_request'],
                   ['script_10', 'sys_firewall::setup_rule'],
                   ['script_11', 'sys_firewall::do_list_rules'],
                   ['script_12', 'sys::do_reconverge_list_enable'],
                   ['script_13', 'sys::do_reconverge_list_disable']
                  ]
        st_ref = @server_templates.detect { |st| st.rs_id.to_i == 27958 }
        load_script_table(st_ref,scripts,st_ref)

        ############################################################################
        # Load Scripts from 'Database Manager for MySQL 5.1 (Chef) - Alpha' [HEAD] #
        ############################################################################
        scripts = [
                   ['script_14', 'db_mysql::setup_block_device'],
                   ['script_15', 'db_mysql::do_backup'],
                   ['script_16', 'db_mysql::do_backup_cloud_files'],
                   ['script_17', 'db_mysql::do_backup_s3'],
                   ['script_18', 'db_mysql::do_backup_ebs'],
                   ['script_19', 'db_mysql::do_restore'],
                   ['script_20', 'db_mysql::do_restore_cloud_files'],
                   ['script_21', 'db_mysql::do_restore_s3'],
                   ['script_22', 'db_mysql::do_restore_ebs'],
                   ['script_23', 'db_mysql::setup_continuous_backups_cloud_files'],
                   ['script_24', 'db_mysql::setup_continuous_backups_s3'],
                   ['script_25', 'db_mysql::setup_continuous_backups_ebs'],
                   ['script_26', 'db_mysql::do_disable_continuous_backups_cloud_files'],
                   ['script_27', 'db_mysql::do_disable_continuous_backups_s3'],
                   ['script_28', 'db_mysql::do_disable_continuous_backups_ebs'],
                   ['script_29', 'db_mysql::do_force_reset'],
                   ['script_30', 'db::do_appservers_allow'],
                   ['script_31', 'db::do_appservers_deny'],
                   ['script_32', 'sys_firewall::setup_rule'],
                   ['script_33', 'sys_firewall::do_list_rules'],
                   ['script_34', 'sys::do_reconverge_list_enable'],
                   ['script_35', 'sys::do_reconverge_list_disable'],
                   ['script_36', 'sys_dns::do_set_private']
                  ]
        st_ref = @server_templates.detect { |st| st.rs_id.to_i == 107666 }
        load_script_table(st_ref,scripts,st_ref)

      end
=end
      # Every instance method included in the runner class that has
      # "exception_handle" in its name is called when an unhandled exception
      # is raised through a behavior (without a verification block). These
      # functions create a library of dynamic exception handling for common
      # scenarios. Exception_handle methods should return true if they have
      # handled the exception, or return false otherwise.
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

      # Every instance method included in the runner class that has
      # "whitelist" in its name is called when the Class is instantiated.
      # These functions add entries to the whitelist for log auditing.
      # The function must return an array of length-3 arrays with the fields
      # as follows:
      #
      # [ "/path/to/log/file", "server_template_name_regex", "matching_regex" ]
      def wishbone_whitelist
        [
          #["/var/log/messages", "Load Balancer (Chef) - Alpha", "harmless"],
          #["/var/log/messages", "Database Manager for MySQL 5.1 (Chef) - Alpha", "ignore"]
        ]
      end

      # Every instance method included in the runner class that has
      # "blacklist" in its name is called when the Class is instantiated.
      # These functions add entries to the blacklist for log auditing.
      # The function must return an array of length-3 arrays with the fields
      # as follows:
      #
      # [ "/path/to/log/file", "server_template_name_regex", "matching_regex" ]
      def wishbone_blacklist
        [
          #["/var/log/messages", "Load Balancer (Chef) - Alpha", "exception"],
          #["/var/log/messages", "Database Manager for MySQL 5.1 (Chef) - Alpha", "error"]
        ]
      end

      # Every instance method included in the runner class that has
      # "needlist" in its name is called when the Class is instantiated.
      # These functions add entries to the needlist for log auditing.
      # The function must return an array of length-3 arrays with the fields
      # as follows:
      #
      # [ "/path/to/log/file", "server_template_name_regex", "matching_regex" ]
      def wishbone_needlist
        [
          #["/var/log/messages", "Load Balancer (Chef) - Alpha", "this should be here"],
          #["/var/log/messages", "Database Manager for MySQL 5.1 (Chef) - Alpha", "required line"]
        ]
      end


	# this function takes in a string parameter and sets that as a tag on each server in the deployment
	# example  tag_to_set = "rs_agent_dev:download_cookbooks_once=true"
#      def tag_all_servers(tag_to_set)
#
#	 servers.each_index { |counter|
   #        servers[counter].settings
 ##          servers[counter].reload
#	   print "tag added " + tag_to_set.to_s + " " + servers[counter].to_s+ "\n"
#	   Tag.set(servers[counter].href,["#{tag_to_set}"]) ## Tag.set expects and array input
 #          servers[counter].tags(true)
#	}
#
 #    end



    end
  end
end
