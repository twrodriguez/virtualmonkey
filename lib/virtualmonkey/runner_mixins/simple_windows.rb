module VirtualMonkey
  module Mixin
    module SimpleWindows
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::Simple
  
      def simple_windows_exception_handle(e)
        puts "Got this \"#{e.message}\"."
        if e.message =~ /timed out waiting for the state to be operational/
          puts "Got \"#{e.message}\". Retrying...."
          sleep 300
          return true # Exception Handled
        elsif e.message =~ /this server is stranded and needs to be operational/
          puts "Got \"#{e.message}\". Retrying...."
          sleep 300
          return true # Exception Handled
        else
          return false
        end
      end
    end
  end
end
