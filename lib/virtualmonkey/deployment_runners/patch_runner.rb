require "rubygems"
require "right_aws"

module VirtualMonkey
  class PatchRunner
    include VirtualMonkey::DeploymentBase
    
    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    # Grab the scripts we plan to exercise
    def patch_lookup_scripts
      scripts = [
                 [ 'test_patch', 'TEST' ]
               ]
      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      load_script_table(st,scripts)
    end 

    def set_user_data(value)
      @servers.each do |server|
        server.settings
        server.ec2_user_data = value
        server.save
      end
    end 
    
    # run the patch test script
    def run_patch_test
      run_script_on_all('test_patch')
    end

   end
end
