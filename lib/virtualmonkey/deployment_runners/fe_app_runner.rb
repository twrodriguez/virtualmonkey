module VirtualMonkey
  class FeAppRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::ApplicationFrontend
    include VirtualMonkey::ApplicationFrontendLookupScripts

   end
end
