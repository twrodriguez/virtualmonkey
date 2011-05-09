module VirtualMonkey
  class OnboardingRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::Mysql

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    def run_onboarding_checks
      # check that the standard unified app is responding on port 80
      @servers.each do |server| 
        url_base = "#{server.dns_name}:#{80}"
        behavior(:test_http_response, "Congratulations", "#{url_base}", 80)
      end
    end

# Check for specific passenger data.
    def check_passenger_monitoring
      passenger_plugins = [
                        {"plugin_name"=>"passenger", "plugin_type"=>"passenger_instances","field"=>"value"},
                        {"plugin_name"=>"passenger", "plugin_type"=>"passenger_processes","field"=>"max"},
                        {"plugin_name"=>"passenger", "plugin_type"=>"passenger_queued","field"=>"value"},
                        {"plugin_name"=>"passenger", "plugin_type"=>"passenger_requests","field"=>"value"}
                      ]
      sleep 60 # wait for some data to be available
      @servers.each do |server|
        unless server.multicloud
#passenger commands to generate data for collectd to return
#          for ii in 1...100
#            # how do we force there to be data??  For now just check that the graph exists - cause the
#            # bug was missing graphs.
#          end
          passenger_plugins.each do |plugin|
            monitor = obj_behavior(server, :get_sketchy_data, {'start' => -60,
                                                               'end' => -20,
                                                               'plugin_name' => plugin['plugin_name'],
                                                               'plugin_type' => plugin['plugin_type']})
            value = monitor['data']["#{plugin['field']}"]
            puts "Checking #{plugin['plugin_name']}-#{plugin['plugin_type']}: value #{value}"
            raise "No #{plugin['plugin_name']}-#{plugin['plugin_type']} data" unless value.length > 0
#            # Need to check for that there is at least one non 0 value returned.
#            for nn in 0...value.length
#              if value[nn] > 0
#                break
#              end
#            end
#            raise "No #{plugin['plugin_name']}-#{plugin['plugin_type']} time" unless nn < value.length
            puts "Monitoring is OK for #{plugin['plugin_name']}-#{plugin['plugin_type']}"
          end
        end
      end
    end
  end
end
