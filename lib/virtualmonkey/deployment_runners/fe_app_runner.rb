module VirtualMonkey
  module Runner
    class FeApp
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
      include VirtualMonkey::Mixin::ApplicationFrontendLookupScripts

      description "TODO"
    end
  end
end
