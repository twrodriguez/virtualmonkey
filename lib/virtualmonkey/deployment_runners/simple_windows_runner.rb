module VirtualMonkey
  module Runner
    class SimpleBasicWindows
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows

      description "TODO"
    end
  end
end
