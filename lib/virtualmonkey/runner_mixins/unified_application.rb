module VirtualMonkey
  module Mixin
    module UnifiedApplication
      # returns true if the http response contains the expected_string
      # * url<~String> url to perform http request
      # * expected_string<~String> regex compatible string used to match against the response output
      def test_http_responses(url_set, expected_string)
        response_set = url_set.map { |url|
          cmd = "curl -sk #{url} 2> /dev/null "
          puts cmd
          `#{cmd}`
        }
        set_in_agreement = response_set.unanimous? { |response| response =~ /#{expected_string}/ }
#        set_in_agreement = response_set.all? { |response| response =~ /#{expected_string}/ }
#        set_in_agreement ||= !(response_set.any? { |response| response =~ /#{expected_string}/ })
        puts response_set.pretty_inspect unless set_in_agreement
        raise "UnifiedApplication Error: Servers not in agreement!" unless set_in_agreement
        raise "UnifiedApplication Error: Done waiting" unless response_set.first =~ /#{expected_string}/
      end

      def unified_application_exception_handle(e)
        if e.message =~ /UnifiedApplication Error/
          puts "Got \"UnifiedApplication Error\". Retrying...."
          puts e.message
          sleep 6
          return true # Exception Handled
        else
          return false # Exception Not Handled
        end
      end

      def run_unified_application_checks(set = @servers, port = 8000)
        http_checks = [
                        ["html serving succeeded", "/index.html"],
                        ["configuration=.*succeeded", "/appserver/"],
                        ["hostname=", "/serverid/"],
                        ["I am in the db", "/dbread/"]
                      ]
        run_on = select_set(set)
        http_checks.each { |expect_str,rel_path|
          url_set = run_on.map { |s| "#{port==443?"https://":""}#{s.dns_name}:#{port}#{rel_path}" }
          test_http_responses(url_set, expect_str)
        }
      end
    end
  end
end
