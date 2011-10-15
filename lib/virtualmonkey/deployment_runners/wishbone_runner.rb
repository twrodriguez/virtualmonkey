module VirtualMonkey
  module Runner
    class Wishbone
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
      include VirtualMonkey::Mixin::UnifiedApplication
      include VirtualMonkey::Mixin::Frontend
      include VirtualMonkey::Mixin::Chef
      include VirtualMonkey::Mixin::PhpChef
      include VirtualMonkey::Mixin::ChefMysqlHA
      include VirtualMonkey::Mixin::Wishbone

      description "TODO"

      # Override any functions from mixins here
    end
  end
end
