require 'ruby-debug'

module VirtualMonkey
  def self.feature_file=(obj)
    @@feature_file = obj
  end

  def self.feature_file
    @@feature_file ||= nil
  end

def rec_Ary_and_hsh(hsh_or_ary)
    if hsh_or_ary.is_a?(Array)

      hsh_or_ary.each_with_index {|ary_obj, index|
         if(rec_Ary_and_hsh(ary_obj)) # if the element is a server interface true
           hsh_or_ary[index] = ary_obj.nickname
         end
      }
    elsif hsh_or_ary.is_a?(Hash)
     
       hsh_or_ary.each { |key,object|
           if (rec_Ary_and_hsh(hsh_or_ary[key])) # if the element is a server interface true
            hsh_or_ary[key] = object.nickname
           end
        }
    else
      if(hsh_or_ary.is_a?(ServerInterface))     # replace with server Interface
        return true
      else
        return false
      end

    end
 end

  module TestCaseInterface
    def set_var(sym, *args, &block)
      behavior(sym, *args, &block)
    end
  
    
    def behavior(sym, *args, &block)
      begin
        push_rerun_test
        #pre-command
        populate_settings if @deployment
        
        #luke code begins here  ***********************
        empty_array = []
        
        #check if the stack is not empty
        if(!@rerun_last_command.empty?)
            
              new_array = [] 
              args.each{|item|
                  if( item.is_a?(Hash) or item.is_a?(String)or item.is_a?(Array))
                    new_array << item.inspect          
                  elsif (item.is_a?(ServerInterface)or item.is_a?(Server))
                    new_array << item.nickname
                  end   
                    
              }
               add_hash = { (sym.to_s + "(#{new_array.join(", ")})") => empty_array}
                           
               if(@rerun_last_command.length > (@stack_objects.length-1))
                  if(@rerun_last_command.length == 1)
                     @stack_objects.clear # clear the objects stack because this is a new stack call     
                     VirtualMonkey::feature_file <<  add_hash if VirtualMonkey::feature_file 
                     @stack_objects.push(VirtualMonkey::feature_file)if VirtualMonkey::feature_file
                     @stack_objects.push(empty_array)
                     @iterating_stack = VirtualMonkey::feature_file if VirtualMonkey::feature_file  # point the iterating_stack to the feature file object
                  else
                     @iterating_stack  = @stack_objects.last # get the last objevt from the object stack
                     @iterating_stack <<   add_hash # here were are adding to iterating stack
                     @stack_objects.push(empty_array)
                 end
              elsif(@rerun_last_command.length < (@stack_objects.length-1))
                 @stack_objects.pop(@stack_objects.length - @rerun_last_command.length)
                 @iterating_stack  = @stack_objects.last # get the last objevt from the object stack
                 @iterating_stack <<  add_hash # here were are adding to iterating stack
                 @stack_objects.push(empty_array)
              else
               @iterating_stack <<  add_hash# here were are adding to iterating stack
               @stack_objects.pop
               @stack_objects.push(empty_array)

              end
     end
        #luke code ends here **************************
        #command
        result = __send__(sym, *args)
        if block
          raise "FATAL: Failed behavior verification. Result was:\n#{result.inspect}" if not yield(result)
        end
        #post-command
        continue_test
      rescue Exception => e
        if block and e.message !~ /^FATAL: Failed behavior verification/
          dev_mode?(e) if not yield(e)
        else
          dev_mode?(e)
        end
      end while @rerun_last_command.pop
      result
    end

    def probe(set, command, &block)
      # run command on set over ssh
      result = ""
      select_ary_set = select_set(set)
      #my_printable_ary = select_ary_set.map {|s| s.nickname }

     my_printable_ary  = select_ary_set
      
               print "rerun:" +@rerun_last_command.length.to_s  + "\n"

               if(@rerun_last_command.length ==0 )
                @stack_objects.clear # clear the objects stack because this is a new stack call     
                empty_array = []
                new_array = []
                new_array << select_ary_set.inspect 
                add_hash = {new_array.join(", ")=> empty_array}
                print "rerun:" +@rerun_last_command.length.to_s  + "\n"
                @stack_objects.push(VirtualMonkey::feature_file)if VirtualMonkey::feature_file
                
                add_probe_command(command)
               
                 @iterating_stack = @stack_objects.last
                @iterating_stack << add_hash
                @stack_objects.push(empty_array)
               elsif(!@rerun_last_command.empty?)
            
                empty_array = []
                new_array = []
                new_array << select_ary_set.inspect 
                add_hash = {new_array.join(", ")=> empty_array}
                print "rerun:" +@rerun_last_command.length.to_s  + "\n"
                
                  if(@rerun_last_command.length > (@stack_objects.length-1))
                     add_probe_command(command)
                     @iterating_stack  = @stack_objects.last # get the last objevt from the object stack
                     @iterating_stack <<   add_hash # here were are adding to iterating stack
                     @stack_objects.push(empty_array)
        
                  elsif(@rerun_last_command.length < (@stack_objects.length-1))
                   @stack_objects.pop(@stack_objects.length - @rerun_last_command.length)
                  add_probe_command(command)
                  @iterating_stack  = @stack_objects.last # get the last objevt from the object stack
                  @iterating_stack  = @stack_objects.last # get the last objevt from the object stack
                  @iterating_stack <<  add_hash # here were are adding to iterating stack
                  @stack_objects.push(empty_array)
                else
                  add_probe_command(command)
                  @iterating_stack  = @stack_objects.last # get the last objevt from the object stack
                  @iterating_stack <<  add_hash# here were are adding to iterating stack
                  @stack_objects.pop
                  @stack_objects.push(empty_array)
                end
             end

        return # ****************** take me out please****************** 
      select_ary_set.each { |s|
        begin
          push_rerun_test
          result_temp = s.spot_check_command(command)
          if not yield(result_temp[:output],result_temp[:status])
            raise "FATAL: Server #{s.nickname} failed probe. Got #{result_temp[:output]}"
          end
          continue_test
        rescue Exception => e
          dev_mode?(e)
        end while @rerun_last_command.pop
        result += result_temp[:output]
      }
    end

    def add_probe_command(command)
       command_empty = []
       add_command = {"probe-command:"+(command.inspect) => command_empty} 
       @iterating_stack  = @stack_objects.last # get the last objevt from the object stack
       @iterating_stack <<   add_command # here were are adding to iterating stack
       @stack_objects.push(command_empty)
    end

    def dev_mode?(e = nil)
      if ENV['MONKEY_NO_DEBUG'] !~ /true/i
        puts "Got exception: #{e.message}" if e
        puts "Backtrace: #{e.backtrace.join("\n")}" if e
        puts "Pausing for debugging..."
        debugger
      elsif e
        self.__send__(:__exception_handle__, e)
      else
        raise "'dev_mode?' function called improperly. An Exception needs to be passed or ENV['MONKEY_NO_DEBUG'] must not be set to 'true'"
      end
    end

    private

    def __exception_handle__(e)
      all_methods = self.methods + self.private_methods
      exception_handle_methods = all_methods.select { |m| m =~ /exception_handle/ and m != "__exception_handle__" }
      
      exception_handle_methods.each { |m|
        begin
          self.__send__(m,e)
          # If an exception_handle method doesn't raise an exception, it handled correctly
          return "Exception Handled"
        rescue
        end
      }
      raise e
    end

    def __list_loader__
      all_methods = self.methods + self.private_methods
      ["whitelist", "blacklist", "needlist"].each do |list|
        list_methods = all_methods.select { |m| m =~ /#{list}/ }
        list_methods.each do |m|
          result = self.__send__(m)
          @log_checklists[list] += result if result.is_a?(Array)
        end
      end
    end

    def help
      puts "Here are some of the wrapper methods that may be of use to you in your debugging quest:\n"
      puts "behavior(sym, *args, &block): Pass the method name (as a symbol or string) and the optional arguments"
      puts "                              that you wish to pass to that method; behavior() will call that method"
      puts "                              with those arguments while handling nested exceptions, retries, and"
      puts "                              debugger calls. If a block is passed, it should take one argument, the"
      puts "                              return value of the function 'sym'. The block should always check"
      puts "                              if the return value is an Exception or not, and validate accordingly.\n"
      puts "                              Examples:"
      puts "                                behavior(:launch_all)"
      puts "                                behavior(:launch_set, 'Load Balancer')"
      puts "                                behavior(:run_script_on_all, 'fail') { |r| r.is_a?(Exception) }\n"
      puts "probe(server_set, shell_command, &block): Provides a one-line interface for running a command on"
      puts "                                          a set of servers and verifying their output. The block"
      puts "                                          should take one argument, the output string from one of"
      puts "                                          the servers, and return true or false based on however"
      puts "                                          the developer wants to verify correctness.\n"
      puts "                                          Examples:"
      puts "                                            probe('.*', 'ls') { |s| puts s }"
      puts "                                            probe(:fe_servers, 'ls') { |s| puts s }"
      puts "                                            probe('app_servers', 'ls') { |s| puts s }"
      puts "                                            probe('.*', 'uname -a') { |s| s =~ /x64/ }\n"
      puts "continue_test: Disables the retry loop that reruns the last command (the current command that you're"
      puts "               debugging.\n"
      puts "help: Prints this help message."
    end

    def populate_settings
      unless @populated
        @servers = @deployment.servers_no_reload
        @servers.reject! { |s|
          s.settings
          st = ServerTemplate.find(resource_id(s.server_template_href))
          ret = (st.nickname =~ /virtual *monkey/i)
          @server_templates << st unless ret
          ret
        }
        @server_templates.uniq!
        self.__send__(:__lookup_scripts__)
        self.__send__(:__list_loader__)
        @populated = true
      end
    end

    def select_set(set = @servers)
      if set.is_a?(String)
        if self.respond_to?(set.to_sym)
          set = set.to_sym
        else
          set = @servers.select { |s| s.nickname =~ /#{set}/ }
        end
      end
      set = behavior(set) if set.is_a?(Symbol)
      set = [ set ] unless set.is_a?(Array)
      return set
    end

    def object_behavior(obj, sym, *args, &block)
      begin
        push_rerun_test
        #pre-command
        populate_settings if @deployment
        #command
        result = obj.__send__(sym, *args)
        #post-command
        continue_test
      rescue Exception => e
        dev_mode?(e)
      end while @rerun_last_command.pop
      result
    end

    def push_rerun_test
      @rerun_last_command.push(true)
    end

    def continue_test
      @rerun_last_command.pop
      @rerun_last_command.push(false)
    end
  end
end
