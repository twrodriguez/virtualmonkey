module VirtualMonkey
  class MonkeySelfTestRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::Simple


    def function1
      behavior(:function2)
      behavior(:function2)
      behavior(:function2)
    end
    def function2
      behavior(:function3)
      behavior(:function3)
      behavior(:function3)
    end
    def function3(lala)
      behavior(:function4, 'rello','reppa')
    end
    def function4(rello, ching)
      behavior(:function5)
      behavior(:function5)
      behavior(:function5)
      behavior(:function5)
    end
    def function5
      set = ["hello1","hello2","hello3","hello4"]
  #return "hello"     
    end
    #def monkey_self_test_lookup_scripts
    
# scripts = [
 #                [ 'test', 'exit value' ]
  #             ]
  #    st = ServerTemplate.find(resource_id(s_one.server_template_href))
   #   load_script_table(st,scripts)
    #end
  end
end
