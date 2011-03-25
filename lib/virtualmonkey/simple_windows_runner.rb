module VirtualMonkey
  class SimpleBasicWindowsRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::Simple
    def exception_handle(e)
      puts "ATTENTION: Using default exception_handle(e). This can be overridden in mixin classes."
      puts "Got this \"#{e.message}\"."
      if e.message =~ /timed out waiting for the state to be operational/
        puts "Got \"#{e.message}\". Retrying...."
        sleep 60
      elsif e.message =~ /this server is stranded and needs to be operational/
        puts "Got \"#{e.message}\". Retrying...."
        sleep 60
      else
        raise e
      end
    end
  end
end
