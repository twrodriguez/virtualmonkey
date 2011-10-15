module VirtualMonkey
  module Runner
    class MysqlChef
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ChefEBS
      include VirtualMonkey::Mixin::ChefMysql
      include VirtualMonkey::Mixin::Chef
      attr_accessor :scripts_to_run
      attr_accessor :db_ebs_prefix

      description "TODO"
    end
  end
end
