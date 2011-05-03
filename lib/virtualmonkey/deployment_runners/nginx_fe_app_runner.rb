module VirtualMonkey
  class NginxFeAppRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::NginxApplicationFrontend
   end
end
