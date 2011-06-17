module VirtualMonkey
  module Runner
    class RailsAioDeveloperChef
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::ApplicationFrontend
    end
  end
end 
