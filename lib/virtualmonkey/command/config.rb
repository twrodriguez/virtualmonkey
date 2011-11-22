module VirtualMonkey
  module Command
    # Config commands
    @@command_flags.merge!("config" => [])
    def self.config(*args)
      self.init(*args)
      @@command = "config"

      unless class_variable_defined?("@@config_help_message")
        @@config_help_message = "  monkey config [options...]\n\n "
        @@config_help_message += @@available_commands[@@command.to_sym] + "\n"
        @@config_help_message += pretty_help_message(ConfigOptions)
      end

      @@last_command_line = "#{@@command} #{ARGV.join(" ")}"

      # Variable Initialization
      config_file = VirtualMonkey::ROOT_CONFIG
      configuration = VirtualMonkey::config.dup

      # Print Help?
      if ARGV.empty? or not (ARGV & ['--help', '-h', 'help']).empty?
        if ARGV.empty?
          puts pretty_help_message(configuration) unless configuration.empty?
        end
        puts "\n#{@@config_help_message}\n\n"
        exit(0)
      end

      # Subcommands
      improper_argument_error = word_wrap("FATAL: Improper arguments for command '#{ARGV[0]}'.\n\n#{@@config_help_message}\n")

      case ARGV[0]
      when "set", "-s", "--set", "add", "-a", "--add"
        if ARGV.length == 1
          # print catalog
          puts "\n  Available config variables:\n\n#{self.pretty_help_message(ConfigVariables)}\n\n"
        else
          error improper_argument_error if ARGV.length != 3
          if check_variable_value(ARGV[1], ARGV[2])
            configuration[ARGV[1].to_sym] = convert_value(ARGV[2], ConfigVariables[ARGV[1].to_s]["values"])
          else
            error "FATAL: Invalid variable or value. Run 'monkey config catalog' to view available variables."
          end
          File.open(config_file, "w") { |f| f.write(configuration.to_yaml) }
        end

      when "edit", "-e", "--edit"
        error improper_argument_error if ARGV.length != 1
        editor = `git config --get core.editor`.chomp
        editor = "vim" if editor.empty?
        config_ok = false
        puts "\n  Available config variables:\n\n#{self.pretty_help_message(ConfigVariables)}\n\n"
        ask("Press Enter to edit using #{editor}")
        until config_ok
          exit_status = system("#{editor} '#{config_file}'")
          begin
            temp_config = YAML::load(IO.read(config_file))
            config_ok = temp_config.reduce(exit_status) do |bool,ary|
              bool && check_variable_value(ary[0], ary[1])
            end
            raise "Invalid variable or variable value in config file" unless config_ok
          rescue Exception => e
            warn e.message
            ask("Press enter to continue editing")
          end
        end

      when "unset", "-u", "--unset"
        error improper_argument_error if ARGV.length != 2
        if ConfigVariables.keys.include?(ARGV[1])
          configuration.delete(ARGV[1].to_sym)
        else
          error "FATAL: '#{ARGV[1]}' is an invalid variable.\n  Available config variables:\n\n#{self.pretty_help_message(ConfigVariables)}\n\n"
        end
        File.open(config_file, "w") { |f| f.write(configuration.to_yaml) }

      when "list", "-l", "--list"
        error improper_argument_error if ARGV.length != 1
        message = ""
        if configuration.empty?
          message = "  No variables configured.".apply_color(:yellow)
        else
          message = pretty_help_message(configuration)
        end
        puts "\n  monkey config list\n\n#{message}\n\n"

      when "catalog", "-c", "--catalog"
        error improper_argument_error if ARGV.length != 1
        puts "\n  monkey config catalog\n\n#{self.pretty_help_message(ConfigVariables)}\n\n"

      when "get", "-g", "--get"
        error improper_argument_error if ARGV.length != 2
        if ConfigVariables.keys.include?(ARGV[1])
          puts configuration[ARGV[1]]
        else
          error "FATAL: '#{ARGV[1]}' is an invalid variable.\n  Available config variables:\n\n#{self.pretty_help_message(ConfigVariables)}\n\n"
        end

      else
        error "FATAL: '#{ARGV[0]}' is an invalid command.\n\n#{@@config_help_message}\n"
      end

      puts ("Command 'monkey #{@@last_command_line}' finished successfully.").apply_color(:green)
      reset()
    end

    def self.convert_value(val, values)
      case values
      when Array then return convert_value(val, values.first.class)
      when Class, Module # Integer, String, Symbol, Boolean
        case values.to_s
        when "Integer" then return val.to_i
        when "String" then return val.to_s
        when "Symbol" then return val.to_s.to_sym
        when "Boolean" then return val == "true" || val == true
        else
          raise TypeError.new("can't convert #{val.class} into #{values}")
        end
      end
    end

    def self.check_variable_value(var, val)
      key_exists = ConfigVariables.keys.include?("#{var}")
      val_valid = false
      if key_exists
        values = ConfigVariables["#{var}"]["values"]
        if values.is_a?(Array)
          val_valid = values.include?(val)
        elsif values.is_a?(Class) # Integer, String, Symbol
          val_valid = convert_value(val, values).is_a?(values)
        end
      end
      key_exists && val_valid
    end

  end
end
