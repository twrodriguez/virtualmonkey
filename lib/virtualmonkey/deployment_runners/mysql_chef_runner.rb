module VirtualMonkey
  class MysqlChefRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::ChefEBS
    include VirtualMonkey::ChefMysql
    include VirtualMonkey::Chef
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    # lookup all the RightScripts that we will want to run
    def mysql_lookup_scripts
     scripts = [
                 [ 'backup', 'db_mysql::do_backup' ],
                 [ 'restore', 'db_mysql::do_restore' ]
               ]
      raise "FATAL: Need 1 MySQL servers in the deployment" unless @servers.size == 1

      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      load_script_table(st,scripts)
#      VirtualMonkey::Chef.chef_download_once_lookup_scripts
    end
  end
end
