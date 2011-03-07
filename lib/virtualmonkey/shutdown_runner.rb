module VirtualMonkey
  class ShutdownRunner
    include VirtualMonkey::DeploymentRunner
    
    def lookup_scripts
      scripts = [
                 [ 'shutdown', 'TEST shutdown' ]
               ]
      st = ServerTemplate.find(s_one.server_template_href.split(/\//).last.to_i)
      lookup_scripts_table(st,scripts)
    end
    
  end
end
