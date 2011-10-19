module VirtualMonkey
  module Mixin
    module FrontEndLookupScripts
      extend VirtualMonkey::Mixin::CommandHooks
      def frontend_lookup_scripts
        fe_scripts = [
                      [ 'apache_restart', 'WEB apache \(re\)start' ],
                      [ 'https_vhost', 'WEB apache FrontEnd https vhost' ]
                     ]
        app_scripts = [
                       [ 'connect', 'LB [app|application|mongrels]+ to HA[ pP]+roxy connect' ]
                      ]
        st = match_st_by_server(fe_servers.first)
        load_script_table(st,fe_scripts)
        st = match_st_by_server(app_servers.first)
        load_script_table(st,app_scripts)
      end
    end
  end
end
