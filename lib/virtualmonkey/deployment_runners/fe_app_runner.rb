module VirtualMonkey
  module Runner
    class FeApp
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
      include VirtualMonkey::Mixin::ApplicationFrontendLookupScripts
    end
  end
end
