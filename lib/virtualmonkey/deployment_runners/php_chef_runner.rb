module VirtualMonkey
  module Runner
    class PhpChef
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
      include VirtualMonkey::Mixin::UnifiedApplication
      include VirtualMonkey::Mixin::Frontend
      include VirtualMonkey::Mixin::Chef

      def detach_checks
        probe(fe_servers, "sed -n '/^[ \t]*server/p' /home/haproxy/rightscale_lb.cfg") { |result, status|
          raise "Detach failed, servers are left in /home/haproxy/rightscale_lb.cfg - #{result}" unless result.empty?
          raise "Detach failed, status returned #{status}" unless status == 0
          true
        }
      end
  
      def cross_connect_frontends
        run_script_on_all('attach')
      end

      def php_chef_lookup_scripts
        recipes = [
                    [ 'attach', 'lb_haproxy::do_attach_request' ],
                    [ 'attach_all', 'lb_haproxy::do_attach_all' ],
                    [ 'detach', 'lb_haproxy::do_detach_request' ],
                    [ 'update_code', 'app_php::do_update_code' ]
                  ]
        fe_st = ServerTemplate.find(resource_id(fe_servers.first.server_template_href))
        load_script_table(fe_st,recipes)
      end
  
      def test_detach
        run_script_on_all('detach')
        detach_checks
      end
  
      def test_attach_all
        run_script_on_set('attach_all', fe_servers)
      end
  
      def test_attach_request 
        run_script_on_all('attach')
      end
  
      def set_variation_ssl
        @deployment.set_input("web_apache/ssl_enable", "text:true")
        @deployment.set_input("web_apache/ssl_key", "cred:virtual_monkey_key")
        @deployment.set_input("web_apache/ssl_certificate", "cred:virtual_monkey_certificate")
      end	

      def set_variation_http_only
        @deployment.set_input("web_apache/ssl_enable", "text:false")
      end
  
      def ssl_checks
        # TODO: run the unified application checks against port 443 of the frontend servers
      end
    end
  end
end
