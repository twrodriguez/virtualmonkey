module VirtualMonkey
  class OnboardingRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::Mysql

    def lookup_scripts
      @scripts_to_run = {}
      st_id = @servers.first.server_template_href.split(/\//).last.to_i
      st = ServerTemplate.find(st_id)
    end

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    def run_onboarding_checks
      # check that the standard unified app is responding on port 80
      @servers.each do |server| 
        url_base = "#{server.dns_name}:#{80}"
        behavior(:test_http_response, "200 OK", "#{url_base}/index.html", 80)
      end
    end


  end
end
