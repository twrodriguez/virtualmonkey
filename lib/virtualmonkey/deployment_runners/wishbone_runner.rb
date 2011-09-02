module VirtualMonkey
  module Runner
    class Wishbone
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
      include VirtualMonkey::Mixin::UnifiedApplication
      include VirtualMonkey::Mixin::Frontend
      include VirtualMonkey::Mixin::Chef               
      include VirtualMonkey::Mixin::PhpChef
      include VirtualMonkey::Mixin::ChefMysql
      include VirtualMonkey::Mixin::Wishbone

      # Override any functions from mixins here
    end
  end
end
