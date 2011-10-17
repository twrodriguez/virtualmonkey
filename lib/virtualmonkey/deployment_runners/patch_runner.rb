require "right_aws"

module VirtualMonkey
  module Runner
    class Patch
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase

      description "TODO"

      # Grab the scripts we plan to exercise
      def patch_lookup_scripts
        scripts = [
                   [ 'test_patch', 'TEST' ]
                 ]
        st = match_st_by_server(s_one)
        load_script_table(st,scripts)
      end

      def set_user_data(value)
        @servers.each do |server|
          server.settings
          server.ec2_user_data = value
          server.save
        end
      end

      # run the patch test script
      def run_patch_test
        run_script_on_all('test_patch')
      end

     end
  end
end
