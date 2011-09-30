module VirtualMonkey
  module Runner
    class SimpleWindowsAD
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows
  
      def server_ad
          @servers.select { |s| s.nickname =~ /Active/i }.first
      end
  
      def oleg_windows_ad_lookup_scripts
       scripts = [
                   [ 'AD Create a new user', 'AD Create a new user' ],
                   [ 'AD Create a new group', 'AD Create a new group' ],
                   [ 'AD Create system state backup', 'AD Create system state backup' ],
                   [ 'AD Restore from backup', 'AD Restore from backup' ],
                   [ 'AD Transferring FSMO roles', 'AD Transferring FSMO roles' ],
                   [ 'AD Bulk create new user', 'AD Bulk create new user' ],
                   [ 'AD Change Administrator password', 'AD Change Administrator password' ],
                   [ 'AD Rebuild domain shares', 'AD Rebuild domain shares' ],
                   [ 'SYS Change to safe boot mode', 'SYS Change to safe boot mode' ],
                   [ 'SYS Change to normal boot mode', 'SYS Change to normal boot mode' ],
                   [ 'SYS Install AD backup policy', 'SYS Install AD backup policy' ],
                   [ 'AD Install ADFS', 'AD Install ADFS' ],
                 ]
        st = ServerTemplate.find(resource_id(server_ad.server_template_href))
        load_script_table(st,scripts)
        load_script('AD monkey test', RightScript.new('href' => "/api/acct/2901/right_scripts/438784"))
        load_script('SYS Install AD Backup Policy CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/438867"))
        load_script('AD create a new user CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/438800"))
        load_script('AD create a new group CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/438798"))
        load_script('AD bulk add user CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/438797"))
        load_script('AD install ADFS CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/438869"))
        load_script('SYS change to safe boot mode CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/438905"))
        load_script('SYS change to normal boot mode CHECK', RightScript.new('href' => "/api/acct/2901/right_scripts/438874"))
      end
    end
  end
end
