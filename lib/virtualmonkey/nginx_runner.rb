module VirtualMonkey
  class NginxRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::Mysql

    def lookup_scripts
      @scripts_to_run = {}
      st_id = @servers.first.server_template_href.split(/\//).last.to_i
      st = ServerTemplate.find(st_id)
      @scripts_to_run["backup"] = st.executables.detect { |ex| ex.name =~ /mysqldump backup/ }
      @scripts_to_run["restart_nginx"] = st.executables.detect { |ex| ex.name =~ /\(re\)start/ }
    end

    private

    def run_nginx_checks
      # check that the standard unified app is responding on port 80
      run_unified_application_checks(@servers, 80)     
    end

  end
end
