module VirtualMonkey
  module Mixin
    module Frontend
      extend VirtualMonkey::Mixin::CommandHooks
      # returns an Array of the Front End servers in the deployment
      def fe_servers
        res = []
        @servers.each do |server|
          st = ServerTemplate.find(resource_id(server.server_template_href))
          if st.nickname =~ /Front End/ || st.nickname =~ /FrontEnd/ || st.nickname =~ /Apache with HAproxy/ || st.nickname =~ /Load Balancer/
            res << server
          end
        end
        raise "FATAL: No frontend servers found" unless res.length > 0
        res
      end

      # returns String with all the private dns of the Front End servers
      # used for setting the LB_HOSTNAME input.
      def get_lb_hostname_input
        lb_hostname_input = "text:"
        fe_servers.each do |fe|
          timeout = 30
          loopcounter = 0
          begin
            if fe.settings['private-dns-name'] == nil
              raise "FATAL: private DNS name is empty" if loopcounter > 10
              sleep(timeout)
              loopcounter += 1
              next
            end
            lb_hostname_input << fe.settings['private-dns-name'] + " "
            done = true
          end while !done
        end
        lb_hostname_input
      end

      def frontend_checks(fe_port=80)
        detect_os

        run_unified_application_checks(fe_servers, fe_port)

        # check that all application servers exist in the haproxy config file on all fe_servers
        server_ips = Array.new

         app_servers.each do |app|
           if app.private_ip
             puts "TEST: private - using #{app.private_ip}"
             server_ips << app.private_ip
           elsif app.reachable_ip
             puts "TEST: dns - using #{app.reachable_ip}"
             server_ips << app.reachable_ip
           else
             raise "FATAL: no private_ip or dns_name for app servers"
           end
         end

        fe_servers.each do |fe|
          fe.settings
          haproxy_config = fe.spot_check_command('flock -n /home/haproxy/rightscale_lb.cfg -c "cat /home/haproxy/rightscale_lb.cfg | grep server"')
          puts "INFO: flock status was #{haproxy_config[:status]}"
          server_ips.each do |ip|
            if haproxy_config.to_s.include?(ip) == false
              puts haproxy_config[:output]
              raise "FATAL: haproxy config did not contain server ip #{ip}"
            end
          end
        end

        # restart haproxy and check that it succeeds
        fe_servers.each_with_index do |server,i|
          response = probe(server, 'service haproxy stop')
          raise "Haproxy stop command failed" unless response

          stopped = false
          count = 0
          until response || count > 3 do
            response = server.spot_check_command(server.haproxy_check)
            stopped = response.include?("not running")
            break if stopped
            count += 1
            sleep 10
          end

          response = probe(server, 'service haproxy start')
          raise "Haproxy start failed" unless response
        end
=begin
        # restart apache and check that it succeeds
       run_script_on_set('apache_restart', fe_servers, true)
        fe_servers.each_with_index do |server,i|
          response = nil
          count = 0
          until response || count > 3 do
            response = probe(server, server.apache_check)
            break if response
            count += 1
            sleep 10
          end
          raise "Apache status failed" unless response
        end
=end
      end

      def cross_connect_frontends
        options = { :LB_HOSTNAME =>get_lb_hostname_input }
       run_script_on_set('connect', fe_servers, true, options)
      end

      def setup_https_vhost
       run_script_on_set(fe_servers, 'https_vhost')
        fe_servers.each_with_index do |server,i|
         test_http_response("html serving succeeded", "https://" + server.reachable_ip + "/index.html", "443")
        end
      end

      # Run spot checks for FE servers in the deployment
      def run_fe_tests
      end

      # Special startup sequence for an FE deployment
      def startup
      end

    end
  end
end
