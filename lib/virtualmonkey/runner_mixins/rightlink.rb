module VirtualMonkey
  module Mixin
    module Rightlink
      # Every instance method included in the runner class that has
      # "lookup_scripts" in its name is called when the Class is instantiated.
      # These functions help to create a hash table of RightScripts and/or
      # Chef Recipes that can be called on a given Server in the deployment.
      # By default, the functions that are used to create this hash table
      # allow every referenced Executable to be run on every server in the
      # deployment, but they can be restricted to only certain ServerTemplates
      # in the deployment.
      def rightlink_lookup_scripts
        scripts = [
                   ['state_test_check', 'rightlink_test::state_test_check_value'],
                   ['remote_recipe_test', 'rightlink_test::resource_remote_recipe_test_start'],
                   ['resource_remote_ping', 'rightlink_test::resource_remote_recipe_ping'],
                   ['resource_remote_pong', 'rightlink_test::resource_remote_recipe_pong'],
                   ['persist_test_check', 'rightlink_test::persist_test_check'],
                   ['depend_check', 'foo::depend_check'],
                   ['iteration_check', 'rightlink_test::iteration_output_test'],
                   ['print_inputs', 'MD_Print_Inputs']
                  ]
        st = ServerTemplate.find(123803)
        load_script_table(st,scripts)

      end
      # Every instance method included in the runner class that has
      # "exception_handle" in its name is called when an unhandled exception
      # is raised through a behavior (without a verification block). These
      # functions create a library of dynamic exception handling for common
      # scenarios. Exception_handle methods should return true if they have
      # handled the exception, or return false otherwise.
      #def rightlink_exception_handle
       # if e.message =~ /INSERT YOUR ERROR HERE/
       #   puts "Got "INSERT YOUR ERROR HERE". Retrying..."
        #  sleep 30
        #  return true # Exception Handled
        #else
        #  return false # Exception Not Handled
        #end
     # end
      # Every instance method included in the runner class that has
      # "whitelist" in its name is called when the Class is instantiated.
      # These functions add entries to the whitelist for log auditing.
      def rightlink_whitelist
        [
          #["/var/log/messages", "#<ServerTemplate:0xb65f44a0>", "exception"],
          #["/var/log/messages", "#<ServerTemplate:0xb65f44a0>", "error"]
        ]
      end
      # Every instance method included in the runner class that has
      # "blacklist" in its name is called when the Class is instantiated.
      # These functions add entries to the blacklist for log auditing.
      def rightlink_blacklist
        [
          #["/var/log/messages", "#<ServerTemplate:0xb65f44a0>", "exception"],
          #["/var/log/messages", "#<ServerTemplate:0xb65f44a0>", "error"]
        ]
      end
      # Every instance method included in the runner class that has
      # "needlist" in its name is called when the Class is instantiated.
      # These functions add entries to the needlist for log auditing.
      def rightlink_needlist
        [
          #["/var/log/messages", "#<ServerTemplate:0xb65f44a0>", "exception"],
          #["/var/log/messages", "#<ServerTemplate:0xb65f44a0>", "error"]
        ]
      end
      
      def test_state_test_check
        run_script_on_all('state_test_check')
      end
      
      def test_remote_recipe_test
        run_script_on_all('remote_recipe_test')
      end
      
      def test_remote_recipe_ping
        run_script_on_all('resource_remote_ping')
      end      
      
      def test_resource_remote_pong
        run_script_on_all('resource_remote_pong')
      end
      
      def test_persist_test_check
        run_script_on_all('persist_test_check')
      end

      def test_depend_check
        run_script_on_all('depend_check')
      end

      def test_iteration_check
        run_script_on_all('iteration_check')
      end

      def test_print_inputs
        run_script_on_all('print_inputs')
      end


    end
  end
end
