module VirtualMonkey
  module Runner
    class SimpleWindowsAD
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows
  
      def server_ad
          @servers.select { |s| s.nickname =~ /Database/i }.first
      end
  
      def oleg_windows_sql_lookup_scripts
       scripts = [
                   [ 'AD change Administrator password', 'AD change Administrator password' ],
                   [ 'AD create a backup', 'AD create a backup' ],
                   [ 'AD create a new group', 'AD create a new group' ],
                   [ 'AD create a new user', 'AD create a new user' ],
                   [ 'AD bulk add user', 'AD bulk add user' ],
                   [ 'SYS change to safe boot mode', 'SYS change to safe boot mode' ],
                   [ 'AD restore from backup', 'AD restore from backup' ],
                   [ 'AD recreate domain shares', 'AD recreate domain shares' ],
                   [ 'AD install ADFS', 'AD install ADFS' ],
                   [ 'SYS Install AD Backup Policy', 'SYS Install AD Backup Policy' ],
                 ]
        st = ServerTemplate.find(resource_id(server_ad.server_template_href))
        load_script_table(st,scripts)
        load_script('AD monkey test', RightScript.new('href' => "/api/acct/2901/right_scripts/416272"))
        load_script('SYS Install AD Backup Policy CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/417111"))
        load_script('AD create a new user CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/417115"))
        load_script('AD create a new group CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/417117"))
        load_script('AD bulk add user CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/417157"))
        load_script('AD install ADFS CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/418000"))
        load_script('SYS change to safe boot mode CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/417109"))
        load_script('SYS change to normal boot mode CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/417110"))
      end
    end
  end
end
