module VirtualMonkey
  module Mixin
    module Rightlink5_7
      # Every instance method included in the runner class that has
      # "lookup_scripts" in its name is called when the Class is instantiated.
      # These functions help to create a hash table of RightScripts and/or
      # Chef Recipes that can be called on a given Server in the deployment.
      # By default, the functions that are used to create this hash table
      # allow every referenced Executable to be run on every server in the
      # deployment, but they can be restricted to only certain ServerTemplates
      # in the deployment.
      def rightlink_5_7_lookup_scripts
        scripts = [
                   ['run_check_value', 'rightlink_test::state_test_check_value'],
                   ['run_recipe_test_start', 'rightlink_test::resource_remote_recipe_test_start'],
                   ['run_remote_recipe_ping', 'rightlink_test::resource_remote_recipe_ping'],
                   ['run_remote_pong', 'rightlink_test::resource_remote_recipe_pong'],
                   ['run_test_check', 'rightlink_test::persist_test_check'],
                   ['run_depend_check', 'foo::depend_check'],
                   ['run_iteration_output', 'rightlink_test::iteration_output_test']
                  ]
        st = ServerTemplate.find(123739)
        load_script_table(st,scripts)

      end

      def test_run_check_value
	run_script_on_all('run_check_value')
      end

      def test_run_recipe_test_start
        run_script_on_all('run_recipe_test_start')
      end

      def test_run_remote_recipe_ping
	run_script_on_all('run_remote_recipe_ping')
      end

      def test_run_remote_pong
	run_script_on_all('run_remote_pong')
      end

      def test_run_test_check
	run_script_on_all('run_test_check')
      end

      def test_run_depend_check
	run_script_on_all('run_depend_check')
      end

      def test_iteration_output
	run_script_on_all('run_iteration_output')
      end

      # Every instance method included in the runner class that has
      # "exception_handle" in its name is called when an unhandled exception
      # is raised through a behavior (without a verification block). These
      # functions create a library of dynamic exception handling for common
      # scenarios. Exception_handle methods should return true if they have
      # handled the exception, or return false otherwise.
#      def rightlink_5.7_exception_handle
 #       if e.message =~ /INSERT YOUR ERROR HERE/
   #       puts "Got "INSERT YOUR ERROR HERE". Retrying..."
  #        sleep 30
    #      return true # Exception Handled
    #    else
    #      return false # Exception Not Handled
     #   end
     # end
      # Every instance method included in the runner class that has
      # "whitelist" in its name is called when the Class is instantiated.
      # These functions add entries to the whitelist for log auditing.
      def rightlink_5_7_whitelist
        [
          #["/var/log/messages", "#<ServerTemplate:0xb65ca5ec>", "exception"],
          #["/var/log/messages", "#<ServerTemplate:0xb65ca5ec>", "error"]
        ]
      end
      # Every instance method included in the runner class that has
      # "blacklist" in its name is called when the Class is instantiated.
      # These functions add entries to the blacklist for log auditing.
      def rightlink_5_7_blacklist
        [
          #["/var/log/messages", "#<ServerTemplate:0xb65ca5ec>", "exception"],
          #["/var/log/messages", "#<ServerTemplate:0xb65ca5ec>", "error"]
        ]
      end
      # Every instance method included in the runner class that has
      # "needlist" in its name is called when the Class is instantiated.
      # These functions add entries to the needlist for log auditing.
      def rightlink_5_7_needlist
        [
          #["/var/log/messages", "#<ServerTemplate:0xb65ca5ec>", "exception"],
          #["/var/log/messages", "#<ServerTemplate:0xb65ca5ec>", "error"]
        ]
      end
    end
  end
end
