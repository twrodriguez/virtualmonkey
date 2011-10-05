module VirtualMonkey
  module Runner
    class MysqlChef
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ChefEBS
      include VirtualMonkey::Mixin::ChefMysqlHA
      include VirtualMonkey::Mixin::Chef
      attr_accessor :scripts_to_run
      attr_accessor :db_ebs_prefix
    end
  end
end
