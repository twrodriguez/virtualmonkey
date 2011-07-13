module VirtualMonkey
  module Runner
    class PhpChef
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
      include VirtualMonkey::Mixin::UnifiedApplication
      include VirtualMonkey::Mixin::Frontend
      include VirtualMonkey::Mixin::Chef
			include VirtualMonkey::Mixin::PhpChef
      include VirtualMonkey::Mixin::ChefMysql

   end
  end
end
