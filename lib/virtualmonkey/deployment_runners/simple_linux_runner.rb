module VirtualMonkey
  module Runner
    class SimpleLinux
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleLinux

      description "TODO"
    end
  end
end
