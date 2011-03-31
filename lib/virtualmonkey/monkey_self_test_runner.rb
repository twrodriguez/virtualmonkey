module VirtualMonkey
  class MonkeySelfTestRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::Simple

    def lookup_scripts
     scripts = [
                 [ 'test', 'exit value' ]
               ]
      st = ServerTemplate.find(resource_id(s_one.server_template_href))
      lookup_scripts_table(st,scripts)
    end
  end
end
