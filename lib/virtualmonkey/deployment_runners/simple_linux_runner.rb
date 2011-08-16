module VirtualMonkey
  module Runner
    class SimpleLinux
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::SimpleLinux
    end
  end
end
