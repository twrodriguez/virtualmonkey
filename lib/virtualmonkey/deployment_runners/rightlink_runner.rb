module VirtualMonkey
  module Runner
    class Rightlink
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::Rightlink

      description "TODO"

      # Override any functions from mixins here
    end
  end
end
