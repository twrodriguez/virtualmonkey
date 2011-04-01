module VirtualMonkey
  class ShutdownRunner
    include VirtualMonkey::DeploymentBase
    
    def lookup_scripts
      scripts = [
                 [ 'shutdown', 'TEST shutdown' ]
               ]
      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      lookup_scripts_table(st,scripts)
    end
    
  end
end
