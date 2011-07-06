module VirtualMonkey
  module Mixin
    module FrontEndLookupScripts
      def frontend_lookup_scripts
        fe_scripts = [
                      [ 'apache_restart', 'WEB apache \(re\)start' ],
                      [ 'https_vhost', 'WEB apache FrontEnd https vhost' ]
                     ]
        app_scripts = [
                       [ 'connect', 'LB [app|application|mongrels]+ to HA[ pP]+roxy connect' ]
                      ]
        st = ServerTemplate.find(resource_id(fe_servers.first.server_template_href))
        load_script_table(st,fe_scripts)
        st = ServerTemplate.find(resource_id(app_servers.first.server_template_href))
        load_script_table(st,app_scripts)
      end 
    end
  end
end
