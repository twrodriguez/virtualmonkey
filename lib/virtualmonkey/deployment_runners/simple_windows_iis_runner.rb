module VirtualMonkey
  module Runner
    class SimpleWindowsIIS
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows
  
      def server_iis
        #  @servers.select { |s| s.nickname =~ /Microsoft IIS App/i }.first
        st = @server_templates.detect{ |st| st.nickname =~ /Microsoft IIS App/i } 
        match_servers_by_st(st).first
      end
  
      def oleg_windows_iis_lookup_scripts
       scripts = [
                   [ 'IIS Download application code', 'IIS Download application code' ],
                   [ 'IIS Add connection string', 'IIS Add connection string' ],
                   [ 'IIS Switch default website', 'IIS Switch default website' ],
                   [ 'IIS Restart application', 'IIS Restart application' ],
                   [ 'IIS Restart web server', 'IIS Restart web server' ],
                   [ 'AWS Register with ELB', 'AWS Register with ELB' ],
                   [ 'AWS Deregister from ELB', 'AWS Deregister from ELB' ],
                   [ 'SYS Install Web Deploy 2.0', 'SYS Install Web Deploy 2.0' ],
                   [ 'SYS Install .NET Framework 4', 'SYS Install .NET Framework 4' ],
                   [ 'SYS install ASP.NET MVC 3', 'SYS install ASP.NET MVC 3' ],
                 ]
        st = @server_templates.detect{ |st| st.nickname =~ /Microsoft IIS App/i } 
        load_script_table(st,scripts)
        load_script('SYS Install Web Deploy 2.0 check', RightScript.new('href' => "/api/acct//2901/right_scripts/434985"))
        load_script('IIS Restart web server check', RightScript.new('href' => "/api/acct//2901/right_scripts/435028"))
        load_script('IIS monkey tests', RightScript.new('href' => "/api/acct//2901/right_scripts/435044"))
        load_script('SYS install ASP.NET MVC 3 check', RightScript.new('href' => "/api/acct//2901/right_scripts/434989"))
        load_script('SYS Install .NET Framework 4 check', RightScript.new('href' => "/api/acct//2901/right_scripts/434993"))
      end
    end
  end
end
