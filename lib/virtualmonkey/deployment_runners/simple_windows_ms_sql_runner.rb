module VirtualMonkey
  module Runner
    class SimpleWindowsSQL
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows
      include VirtualMonkey::Mixin::SimpleWindowsSQL


      description "TODO"

    end
  end
end
