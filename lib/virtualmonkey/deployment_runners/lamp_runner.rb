module VirtualMonkey
  class LampRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::Mysql

    def lamp_lookup_scripts
      scripts = [
                  [ 'backup', 'mysqldump backup' ],
                  [ 'restart_apache', '\(re\)start' ]
                ]
      st = ServerTemplate.find(resource_id(@servers.first.server_template_href))
      load_script_table(st,scripts)
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

      # check that mysql tmpdir is custom setup on all servers
      query = "show variables like 'tmpdir'"
      query_command = "echo -e \"#{query}\"| mysql"
      @servers.each do |server|
        server.spot_check(query_command) { |result| raise "Failure: tmpdir was unset#{result}" unless result.include?("/mnt/mysqltmp") }
      end

      # check that logrotate has mysqlslow in it
      @servers.each do |server|
        res = server.spot_check_command("logrotate --force -v /etc/logrotate.d/mysql-server")
        raise "LOGROTATE FAILURE, exited with non-zero status" if res[:status] != 0
        raise "DID NOT FIND mysqlslow.log in the log rotation!" if res[:output] !~ /mysqlslow/
      end

    end


  end
end
