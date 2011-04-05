module VirtualMonkey
  module TestCaseInterface
    def set_var(sym, *args, &block)
      behavior(sym, *args, block)
    end

    def behavior(sym, *args, &block)
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
      result
    end

    def probe(set, command, &block)
      # run command on set over ssh
      result = ""
      select_set(set).each { |s|
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
      exception_handle_methods = self.methods.select { |m| m =~ /exception_handle/ and m != "__exception_handle__" }
      
      if e.message =~ /Insufficient capacity/
        puts "Got \"Insufficient capacity\". Retrying...."
        sleep 60
        return "Exception Handled"
      elsif e.message =~ /Service Temporarily Unavailable/
        puts "Got \"Service Temporarily Unavailable\". Retrying...."
        sleep 10
        return "Exception Handled"
      end

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
        __lookup_scripts__
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
