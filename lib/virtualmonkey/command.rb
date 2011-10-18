#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require 'highline/import'
require 'uri'
require 'pp'

module VirtualMonkey
  module Command
    AvailableCommands = {
      :api_check                  => "Verify API version connectivity",
      :clone                      => "Clone a deployment n times and run though feature tests",
      :config                     => "Get and set advanced variables that control VirtualMonkey behavior",
      :create                     => "Create MCI and Cloud permutation Deployments for a set of ServerTemplates",
      :destroy                    => "Destroy a set of Deployments",
      :destroy_ssh_keys           => "Destroy VirtualMonkey-generated SSH Keys",
      :generate_ssh_keys          => "Generate SSH Key files per Cloud and stores their hrefs in ssh_keys.json",
      :import_deployment          => "Import an existing Deployment and create a new testing scenario for it",
      :list                       => "List the full Deployment nicknames and Server statuses for a set of Deployments",
      :new_config                 => "Interactively create a new Troop Config JSON File",
      :new_runner                 => "Interactively create a new testing scenario and all necessary files",
      :populate_all_cloud_vars    => "Calls \"generate_ssh_keys\", \"populate_datacenters\", and \"populate_security_groups\" for all Clouds",
      :populate_datacenters       => "Populates datacenters.json with API 1.5 hrefs per Cloud",
      :populate_security_groups   => "Populates security_groups.json with appropriate hrefs per Cloud",
      :run                        => "Execute a set of feature tests across a set of Deployments in parallel",
      :troop                      => "Calls \"create\", \"run\", and \"destroy\" for a given troop config file",
      :update_inputs              => "Updates the inputs and editable server parameters for a set of Deployments",
      :version                    => "Displays version and exits",
      :help                       => "Displays usage information"
    }

    NonInteractiveCommands = AvailableCommands.reject { |cmd,desc|
      [:new_config, :new_runner, :import_deployment].include?(cmd)
    }

    AvailableQACommands = {
      :alpha      => "",
      :beta       => "",
      :ga         => "",
      :log_audit  => "",
      :port_scan  => "",
      :version    => "Displays version and exits",
      :help       => "Displays usage information"
    }

    Flags = {
      :terminate       => "opt :terminate, 'Terminate if tests successfully complete. (No destroy)',            :short => '-a', :type => :boolean",
      :common_inputs   => "opt :common_inputs, 'Input JSON files to be set at Deployment AND Server levels',    :short => '-c', :type => :strings",
      :deployment      => "opt :deployment, 'regex string to use for matching deployment',                      :short => '-d', :type => :string",
      :config_file     => "opt :config_file, 'Troop Config JSON File',                                          :short => '-f', :type => :string",
      :clouds          => "opt :clouds, 'Space-separated list of cloud_ids to use',                             :short => '-i', :type => :integers",
      :keep            => "opt :keep, 'Do not delete servers or deployments after terminating',                 :short => '-k', :type => :boolean",
      :use_mci         => "opt :use_mci, 'List of MCI hrefs to substitute for the ST-attached MCIs',            :short => '-m', :type => :string, :multi => true",
      :n_copies        => "opt :n_copies, 'Number of clones to make',                                           :short => '-n', :type => :integer, :default => 1",
      :only            => "opt :only, 'Regex string to use for subselection matching on MCIs',                  :short => '-o', :type => :string",
      :no_spot         => "opt :no_spot, 'do not use spot instances',                                           :short => '-p', :type => :boolean, :default => true",
      :no_resume       => "opt :no_resume, 'Do not use trace info to resume a previous test',                   :short => '-r', :type => :boolean",
      :tests           => "opt :tests, 'List of test names to run across Deployments (default is all)',         :short => '-t', :type => :strings",
      :verbose         => "opt :verbose, 'Print all output to STDOUT as well as the log files',                 :short => '-v', :type => :boolean",
      :revisions       => "opt :revisions, 'Specify a list of revision numbers for templates (0 = HEAD)',       :short => '-w', :type => :integers",
      :prefix          => "opt :prefix, 'Prefix of the Deployments',                                            :short => '-x', :type => :string",
      :yes             => "opt :yes, 'Turn off confirmation',                                                   :short => '-y', :type => :boolean",
      :one_deploy      => "opt :one_deploy, 'Load all variations of a single ST into one Deployment',           :short => '-z', :type => :boolean",

      :force           => "opt :force, 'Forces command to attempt to continue even if an exception is raised',  :short => '-F', :type => :boolean",
      :overwrite       => "opt :overwrite, 'Refresh values by replacing existing data',                         :short => '-O', :type => :boolean",
      :report_metadata => "opt :report_metadata, 'Report metadata to SimpleDB',                                 :short => '-R', :type => :boolean",
      :report_tags     => "opt :report_tags, 'Additional tags to help database sorting (e.g. -T sprint28)',     :short => '-T', :type => :strings"
    }

    ConfigOptions = {
      "set"     => "Set a configurable variable               'monkey config [-s|--set|set] name value'",
      "edit"    => "Open config file in your git editor       'monkey config [-e|--edit|edit]'",
      "unset"   => "Unset a configurable variable             'monkey config [-u|--unset|unset] name'",
      "list"    => "List current config variables             'monkey config [-l|--list|list]'",
      "catalog" => "List all possible configurable variables  'monkey config [-c|--catalog|catalog]'",
      "get"     => "Get the value of one variable             'monkey config [-g|--get|get] name'",
      "help"    => "Print this help message                   'monkey config [-h|--help|help]'"
    }

    ConfigVariables = {
      "test_permutation"    => {"description" => "Controls how individual test cases in a feature file get assigned per deployment",
                              "values" => ["distributive", "exhaustive"]},
      "test_ordering"       => {"description" => "Controls how individual test cases in a feature file are ordered for execution",
                              "values" => ["random", "strict"]},
      "feature_mixins"      => {"description" => "Controls how multiple features are distributed amongst available deployments",
                              "values" => ["spanning", "parallel"]},
      "load_progress"       => {"description" => "Turns on/off the display of load progress info for 'monkey' commands",
                              "values" => ["show", "hide"]},
      "colorized_text"      => {"description" => "Turns on/off colorized console text",
                              "values" => ["show", "hide"]},
      "max_retries"         => {"description" => "Controls how many retries to attempt in a scope stack before giving up",
                              "values" => Integer},
      "grinder_subprocess"  => {"description" => "Turns on/off the ability of Grinder to load into the current process",
                              "values" => ["allow_same_process", "force_subprocess"]}
    }

    @@command_flags ||= {}

    def self.init(*args)
      @@global_state_dir = VirtualMonkey::TEST_STATE_DIR
      @@features_dir = VirtualMonkey::FEATURE_DIR
      @@cfg_dir = VirtualMonkey::CONFIG_DIR
      @@runner_dir = VirtualMonkey::RUNNER_DIR
      @@mixin_dir = VirtualMonkey::MIXIN_DIR
      @@cv_dir = VirtualMonkey::CLOUD_VAR_DIR
      @@ci_dir = VirtualMonkey::COMMON_INPUT_DIR
      @@troop_dir = VirtualMonkey::TROOP_DIR

      # Monkey available_commands
      @@available_commands = AvailableCommands

      # QA available_commands
      @@available_qa_commands = AvailableQACommands

      @@flags = Flags

      @@version_string = "VirtualMonkey #{VirtualMonkey::VERSION}"

      # Regular message
      unless class_variable_defined?("@@usage_msg")
        @@usage_msg = "\nValid commands for #{@@version_string}:\n\n"
        max_width = @@available_commands.keys.map { |k| k.to_s.length }.max
        temp = @@available_commands.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
        @@usage_msg += temp.map { |k,v| "  %#{max_width}s:   #{v}" % k }.join("\n")
        @@usage_msg += "\n\nHelp usage: 'monkey help <command>' OR 'monkey <command> --help'\n"
        @@usage_msg += "If this is your first time using VirtualMonkey, start with new_runner and new_config.\n"
        @@usage_msg += "Or, if you already have an example deployment, you can use import_deployment.\n\n"
      end

      # QA Mode message
=begin
      unless class_variable_defined?("@@qa_usage_msg")
        @@qa_usage_msg = "\nValid commands for #{@@version_string} (QA mode):\n\n"
        qa_max_width = @@available_qa_commands.keys.map { |k| k.to_s.length }.max
        temp = @@available_qa_commands.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
        @@qa_usage_msg += temp.map { |k,v| "  %#{qa_max_width}s:   #{v}" % k }.join("\n")
        @@qa_usage_msg += "\n\nHelp usage: 'qa help <command>' OR 'qa <command> --help'\n\n"
      end
=end

      # Parse any passed args and put them in ARGV if they exist
      if args.length > 1
        ARGV.replace args
      elsif args.length == 1
        ARGV.replace args.first.split(/ /)
      end
    end

    # Reset class variables to nil
    def self.reset
      @@dm = nil
      @@gm = nil
      @@remaining_jobs = nil
      @@do_these = nil
      @@command = nil
      @@st_table = nil
      @@individual_server_inputs = nil
      @@st_inputs = nil
      @@common_inputs = nil
      @@last_command_line = nil
    end

    # Parses the initial command string, removing it from ARGV, then runs command.
    def self.go(*args)
      self.init(*args)
      @@command = ARGV.shift || "help"
      if @@available_commands[@@command.to_sym]
        VirtualMonkey::Command.__send__(@@command)
      elsif @@command == "-h" or @@command == "--help"
        VirtualMonkey::Command.help
      else
        warn "Invalid command #{@@command}\n\n#{@@usage_msg}"
        exit(1)
      end
    end

    def self.use_options
      ("text '  monkey #{@@command} [options...]\n\n #{@@available_commands[@@command.to_sym]}';" +
      @@command_flags["#{@@command}"].map { |op| @@flags[op] }.join(";"))
    end

    def self.add_command(command_name, command_flags=[], more_trollop_options=[], &block)
      command_name = command_name.to_s.downcase
      @@command_flags.merge!(command_name => command_flags.sort { |a,b| a.to_s <=> b.to_s })
      self.instance_eval <<EOS
        def #{command_name}(*args)
          self.init(*args)
          @@command = "#{command_name}"
          puts ""
          @@options = Trollop::options do
            eval(VirtualMonkey::Command::use_options)
            #{more_trollop_options.join("; ")}
          end

          @@last_command_line = VirtualMonkey::Command::reconstruct_command_line()
          if @@last_command_line == "#{command_name}"
            ans = ask("Did you mean to run 'monkey #{command_name}' without any options (y/n)?")
            #{command_name}("--help") unless ans =~ /^[yY]/
          end

          self.instance_eval(&(#{block.to_ruby}))
          puts ("\nCommand 'monkey " + @@last_command_line + "' finished successfully.").apply_color(:green)
          reset()
        end
EOS
    end

    # Help command
    @@command_flags.merge!("help" => [])
    def self.help(*args)
      self.init(*args)
      if subcommand = ARGV.shift
        ENV['REST_CONNECTION_LOG'] = "/dev/null"
        @@command = subcommand
        VirtualMonkey::Command.__send__(subcommand, "--help")
      else
        puts @@usage_msg
      end
      reset()
    end

    # Version command
    @@command_flags.merge!("version" => [])
    def self.version(*args)
      self.init(*args)
      puts @@version_string
      reset()
    end

    # Config command
    @@command_flags.merge!("config" => [])
    def self.config(*args)
      self.init(*args)
      @@command = "config"

      unless class_variable_defined?("@@config_help_message")
        @@config_help_message = "  monkey config [options...]\n\n "
        @@config_help_message += @@available_commands[@@command.to_sym] + "\n"
        max_width = ConfigOptions.keys.map { |k| k.to_s.length }.max
        temp = ConfigOptions.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
        @@config_help_message += temp.map { |k,v| "  %#{max_width}s:   #{v}" % k }.join("\n")
      end

      @@last_command_line = ARGV.join(" ")

      if ARGV.empty? or not (ARGV & ['--help', '-h', 'help']).empty?
        puts "\n#{@@config_help_message}\n\n"
        exit(0)
      end

      config_file = VirtualMonkey::ROOT_CONFIG
      configuration = VirtualMonkey::config.dup
      improper_argument_error = "FATAL: Improper arguments for command '#{ARGV[0]}'.\n\n#{@@config_help_message}\n"

      case ARGV[0]
      when "set", "-s", "--set", "add", "-a", "--add"
        error improper_argument_error if ARGV.length != 3

        if check_variable_value(ARGV[1], ARGV[2])
          configuration[ARGV[1].to_sym] = convert_value(ARGV[2], ConfigVariables[ARGV[1].to_s]["values"])
        else
          error "FATAL: Invalid variable or value. Run 'monkey config catalog' to view available variables."
        end
        File.open(config_file, "w") { |f| f.write(configuration.to_yaml) }

      when "edit", "-e", "--edit"
        error improper_argument_error if ARGV.length != 1

        editor = `git config --get core.editor`.chomp
        editor = "vim" if editor.empty?
        config_ok = false
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
          error "FATAL: '#{ARGV[1]}' is an invalid variable. Run 'monkey config catalog' to view available variables."
        end
        File.open(config_file, "w") { |f| f.write(configuration.to_yaml) }

      when "list", "-l", "--list"
        error improper_argument_error if ARGV.length != 1

        max_width = configuration.keys.map { |k| k.to_s.length }.max
        message = configuration.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
        message = message.map { |k,v| "  %#{max_width}s:   #{configuration[k]}" % k }.join("\n")
        puts "\n  monkey config list\n\n#{message}\n\n"

      when "catalog", "-c", "--catalog"
        error improper_argument_error if ARGV.length != 1

        max_key_width = ConfigVariables.keys.map { |k| k.to_s.length }.max
        max_desc_width = ConfigVariables.values.map { |v| v["description"].to_s.length }.max
        message = ConfigVariables.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
        message = message.map { |k,v| "  %#{max_key_width}s:   %-#{max_desc_width}s  Values: #{v["values"].inspect}" % [k, v["description"]] }
        puts "\n  monkey config catalog\n\n#{message.join("\n")}\n\n"

      when "get", "-g", "--get"
        error improper_argument_error if ARGV.length != 2

        if ConfigVariables.keys.include?(ARGV[1])
          puts configuration[ARGV[1]]
        else
          error "FATAL: '#{ARGV[1]}' is an invalid variable. Run 'monkey config catalog' to view available variables."
        end

      else
        error "FATAL: '#{ARGV[0]}' is an invalid command.\n\n#{@@config_help_message}\n"
      end

      puts ("Command 'monkey #{@@last_command_line}' finished successfully.").apply_color(:green)
      reset()
    end

    def self.convert_value(val, values)
      if values.is_a?(Array)
        return convert_value(val, values.first.class)
      elsif values.is_a?(Class) # Integer, String, Symbol
        case values.to_s
        when "Integer" then return val.to_i
        when "String" then return val.to_s
        when "Symbol" then return val.to_s.to_sym
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

    def self.last_command_line
      @@last_command_line ||= ""
    end
  end
end

# Auto-require Section
automatic_require(VirtualMonkey::COMMAND_DIR)
