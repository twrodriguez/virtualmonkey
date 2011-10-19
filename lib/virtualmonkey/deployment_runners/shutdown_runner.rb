module VirtualMonkey
  module Runner
    class Shutdown
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase

      description "TODO"

      def shutdown_lookup_scripts
        scripts = [
                   [ 'shutdown', 'TEST shutdown' ]
                 ]
        st = match_st_by_server(s_one)
        load_script_table(st,scripts)
      end

    end
  end
end
