module VirtualMonkey
  module Runner
    class PhpAioTrialChef
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend

      description "TODO"
    end
  end
end
