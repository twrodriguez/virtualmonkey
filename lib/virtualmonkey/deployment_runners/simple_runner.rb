module VirtualMonkey
  module Runner
    class Simple
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::Simple

      description "TODO"
    end
  end
end
