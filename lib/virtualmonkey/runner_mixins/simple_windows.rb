module VirtualMonkey
  module SimpleWindows
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::Simple

    def simple_windows_exception_handle(e)
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
