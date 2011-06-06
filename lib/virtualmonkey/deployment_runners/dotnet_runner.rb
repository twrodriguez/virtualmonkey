module VirtualMonkey
  class DotnetRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::SimpleWindows
    
    def dotnet_lookup_scripts
      scripts = [
                  [ 'IIS Download application code', 'IIS Download application code' ], 
                  [ 'DB SQLS Download and attach DB', 'DB SQLS Download and attach DB' ], 
                  [ 'DB SQLS Create login', 'DB SQLS Create login' ], 
                  [ 'IIS Switch default website', 'IIS Switch default website' ], 
                  [ 'IIS Add connection string', 'IIS Add connection string' ],
                  [ 'AWS Register with ELB', 'AWS Register with ELB' ], 
                  [ 'AWS Deregister from ELB', 'AWS Deregister from ELB' ]
                ]
      st = ServerTemplate.find(resource_id(@servers.first.server_template_href))
      load_script_table(st, scripts)
    end
  end
end
