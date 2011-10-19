module VirtualMonkey
  module Runner
    class NginxFeApp
      extend VirtualMonkey::Mixin::CommandHooks
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::NginxApplicationFrontend

      description "TODO"
    end
   end
end
