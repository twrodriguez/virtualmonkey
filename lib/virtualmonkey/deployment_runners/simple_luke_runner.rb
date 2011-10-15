module VirtualMonkey
  module Runner
    class SimpleLuke
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::Simple

      description "TODO"
    end
  end
end
