module VirtualMonkey
  module Command
    def self.qa(*args)
      self.init(*args)
      @@command = ARGV.shift
      if @@available_qa_commands[@@command.to_sym]
        VirtualMonkey::Command.__send__("qa_#{@@command}")
      elsif @@command == "-h" or @@command == "--help"
        VirtualMonkey::Command.help
      else
        STDERR.puts "Invalid command #{@@command}\n\n#{@@usage_msg}"
        exit(1)
      end
    end

    def self.qa_audit_logs(*args)
      self.qa_init(*args)
      @@options = Trollop::options do
        text @@available_commands[:audit_logs]
        eval(VirtualMonkey::Command::use_options(:prefix, :only, :config_file))
      end

      raise "--config_file is required" unless @@options[:config_file]
      load_config_file

      @@dm = DeploymentMonk.new(@@options[:prefix])
      select_only_logic("Train lists on")

      @@do_these.each { |d| audit_log_deployment_logic(d, @@options[:list_trainer]) }
    end
  end
end
