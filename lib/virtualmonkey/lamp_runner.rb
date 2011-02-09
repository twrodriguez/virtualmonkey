module VirtualMonkey
  class LampRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::Mysql

    def lookup_scripts
      @scripts_to_run = {}
      st_id = @servers.first.server_template_href.split(/\//).last.to_i
      st = ServerTemplate.find(st_id)
      @scripts_to_run["backup"] = st.executables.detect { |ex| ex.name =~ /mysqldump backup/ }
      @scripts_to_run["restart_apache"] = st.executables.detect { |ex| ex.name =~ /\(re\)start/ }
    end

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    def run_lamp_checks
      # check that the standard unified app is responding on port 80
      run_unified_application_checks(@servers, 80)
      
      # check that running the mysql backup script succeeds
      @servers.first.spot_check_command("/etc/cron.daily/mysql-dump-backup.sh")

      # exercise operational RightScript(s)
      run_script("backup", @servers.first)
      run_script("restart_apache", @servers.first)
      
    end


  end
end
