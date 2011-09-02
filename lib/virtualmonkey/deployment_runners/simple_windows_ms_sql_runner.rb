module VirtualMonkey
  module Runner
    class SimpleWindowsSQL
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleWindows
      include VirtualMonkey::Mixin::SimpleWindowsSQL
  
  
    end
  end
end
