require 'ruby-debug'

module VirtualMonkey
  def self.feature_file=(obj)
    @@feature_file = obj
  end

  def self.feature_file
    @@feature_file ||= nil
  end

  module TestCaseInterface
    def set_var(sym, *args, &block)
      behavior(sym, *args, &block)
    end
  
    def test_case_interface_init
      @log_checklists = {"whitelist" => [], "blacklist" => [], "needlist" => []}
      @rerun_last_command = []
      @stack_objects = []         # array holding the top most objects in the stack
      @iterating_stack = []       # stack that iterates
    end
    
    def behavior(sym, *args, &block)
      execution_stack_trace(sym, args)
      begin
        push_rerun_test
        #pre-command
        populate_settings if @deployment
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
      clean_stack_trace
      result
    end

    def probe(set, command, &block)
      # run command on set over ssh
      result = ""
      set_ary = select_set(set)
      execution_stack_trace("probe", [set_ary, command])

      set_ary.each { |s|
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
      clean_stack_trace
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
      execution_stack_trace(sym, args, obj)
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
      clean_stack_trace
      result
    end

    def push_rerun_test
      @rerun_last_command.push(true)
    end

    def continue_test
      @rerun_last_command.pop
      @rerun_last_command.push(false)
    end

    def execution_stack_trace(sym, args, obj=nil)
      return nil unless VirtualMonkey::feature_file

      referenced_ary = []

      # Stringify Call
      arg_ary = args.map { |item| stringify_arg(item) }
      call = sym.to_s + "(#{arg_ary.join(", ")})"
      call = stringify_arg(obj) + "." + call if obj
      add_hash = { call => referenced_ary }

      # Add string to proper place
      if @rerun_last_command.length < @stack_objects.length # shallower or same level call
        @stack_objects.pop(Math.abs(@stack_objects.length - @rerun_last_command.length))
      end
      if @stack_objects.empty?
        VirtualMonkey::feature_file << add_hash
      else
        @iterating_stack = @stack_objects.last # get the last object from the object stack
        @iterating_stack << add_hash # here were are adding to iterating stack
      end
      @stack_objects << referenced_ary
    end

    def clean_stack_trace
      # This is ugly code...I apologize, but it works
      return nil unless VirtualMonkey::feature_file
      ary = @stack_objects
      ary = VirtualMonkey::feature_file if ary.first.empty?
      ary.each { |temp|
        temp = VirtualMonkey::feature_file unless temp.is_a?(Array)
        temp.each_index { |i|
          if temp[i].is_a?(Hash)
            key = temp[i].keys.first
            if temp[i][key].is_a?(Array) and temp[i][key].empty?
              temp[i] = key
            end
          end
        }
      }
    end

    def stringify_arg(arg, will_be_inspected = false)
      return (will_be_inspected ? arg : arg.inspect) if arg.is_a?(String)
      return stringify_arg(arg.nickname, will_be_inspected) if arg.is_a?(ServerInterface) or arg.is_a?(Server)
      return arg.class.to_s if arg.is_a?(AuditEntry)

      if arg.is_a?(Array)
        new_ary = arg.map { |item| stringify_arg(item, true) }
        return (will_be_inspected ? new_ary : new_ary.inspect)
      end

      if arg.is_a?(Hash)
        new_hsh = {}
        arg.each { |k,v| new_hsh[ stringify_arg(k, true) ] = stringify_arg(v, true) }
        return (will_be_inspected ? new_hsh : new_hsh.inspect)
      end

      return ""
    end
  end
end
