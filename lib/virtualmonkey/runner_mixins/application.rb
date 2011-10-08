require 'timeout'

module VirtualMonkey
  module Mixin
    module Application
      include VirtualMonkey::Mixin::DeploymentBase

      # returns an Array of the App Servers in the deployment
      def app_servers
        ret = []
        @servers.each do |server|
          st = ServerTemplate.find(resource_id(server.server_template_href))
          if st.nickname =~ /AppServer/ || st.nickname =~ /App Server/
            ret << server
          end
        end

        raise "No app servers in deployment" unless ret.length > 0
        ret
      end

      # sets LB_HOSTNAME on the deployment using the private dns of the fe_servers
      def set_lb_hostname
        obj_behavior(@deployment, :set_input, "LB_HOSTNAME",get_lb_hostname_input)
      end

      # returns true if the http response contains the expected_string
      # * url<~String> url to perform http request
      # * expected_string<~String> regex compatible string used to match against the response output
      def test_http_response(expected_string, url, port)
        cmd = "curl -sk #{url} 2> /dev/null "
        puts cmd
        timeout=300
        begin
          status = Timeout::timeout(timeout) do
            while true
              response = `#{cmd}`
              puts response
              break if response.include?(expected_string)
              puts "Retrying...looking for #{expected_string}"
              sleep 5
            end
          end
        rescue Timeout::Error => e
          raise "ERROR: Query failed after #{timeout/60} minutes."
        end
      end

      def run_rails_demo_application_checks(set = @servers, port = 80)
        run_on = select_set(set)
        run_on.each do |server|
          url_base = "#{server.reachable_ip}:#{port}"
         test_http_response("Mephisto", url_base, port)
        end
      end

      # Run spot checks for APP servers in the deployment
      def run_app_tests
      end

      # Special startup sequence for an APP deployment
      def startup
      end

    end
  end
end
