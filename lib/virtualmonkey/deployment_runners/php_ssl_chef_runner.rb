module VirtualMonkey
  class PhpSSLChefRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::Frontend
    include VirtualMonkey::ApplicationFrontend
    include VirtualMonkey::Chef

    def detach_checks
      fe_servers.each do |fe|
        fe.settings
        # lopaka - replaced command with sed to ignore leading whitespaces with lines starting with 'server'
#        haproxy_config = obj_behavior(fe, :spot_check_command, "cat /home/haproxy/rightscale_lb.cfg | grep server |grep -v '^#'")
        haproxy_config = obj_behavior(fe, :spot_check_command, "sed -n '/^[ \t]*server/p' /home/haproxy/rightscale_lb.cfg")
        #raise "Detach failed, servers are left in /home/haproxy/rightscale_lb.cfg - #{haproxy_config}" unless haproxy_config.empty?
        raise "Detach failed, servers are left in /home/haproxy/rightscale_lb.cfg - #{haproxy_config}" unless haproxy_config[:status]
      end
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
      # TODO: set the inputs for SSL
    end	

    def ssl_checks
      # TODO: run the unified application checks against port 443 of the frontend servers
    end

  end
end
