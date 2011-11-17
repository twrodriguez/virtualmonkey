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
      :collateral                 => "Manage test collateral repositories using git",
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
      :terminate       => "opt :terminate, 'Terminate if tests successfully complete. (No destroy)',            :short => '-a',   :type => :boolean",
      :common_inputs   => "opt :common_inputs, 'Input JSON files to be set at Deployment AND Server levels',    :short => '-c',   :type => :strings",
      :deployment      => "opt :deployment, 'regex string to use for matching deployment',                      :short => '-d',   :type => :string",
      :exclude_tests   => "opt :exclude_tests, 'List of test names to exclude from running across Deployments', :short => '-e',   :type => :strings",
      :config_file     => "opt :config_file, 'Troop Config JSON File',                                          :short => '-f',   :type => :string",
      :clouds          => "opt :clouds, 'Space-separated list of cloud_ids to use',                             :short => '-i',   :type => :integers",
      :keep            => "opt :keep, 'Do not delete servers or deployments after terminating',                 :short => '-k',   :type => :boolean",
      :use_mci         => "opt :use_mci, 'List of MCI hrefs to substitute for the ST-attached MCIs',            :short => '-m',   :type => :string, :multi => true",
      :n_copies        => "opt :n_copies, 'Number of clones to make',                                           :short => '-n',   :type => :integer, :default => 1",
      :only            => "opt :only, 'Regex string to use for subselection matching on MCIs',                  :short => '-o',   :type => :string",
      :no_spot         => "opt :no_spot, 'do not use spot instances',                                           :short => :none,  :type => :boolean, :default => true",
      :no_resume       => "opt :no_resume, 'Do not use trace info to resume a previous test',                   :short => '-r',   :type => :boolean",
      :tests           => "opt :tests, 'List of test names to run across Deployments (default is all)',         :short => '-t',   :type => :strings",
      :verbose         => "opt :verbose, 'Print all output to STDOUT as well as the log files',                 :short => '-v',   :type => :boolean",
      :revisions       => "opt :revisions, 'Specify a list of revision numbers for templates (0 = HEAD)',       :short => '-w',   :type => :integers",
      :prefix          => "opt :prefix, 'Prefix of the Deployments',                                            :short => '-x',   :type => :string",
      :yes             => "opt :yes, 'Turn off confirmation',                                                   :short => '-y',   :type => :boolean",
      :one_deploy      => "opt :one_deploy, 'Load all variations of a single ST into one Deployment',           :short => '-z',   :type => :boolean",

      :force           => "opt :force, 'Forces command to attempt to continue even if an exception is raised',  :short => '-F', :type => :boolean",
      :overwrite       => "opt :overwrite, 'Replace existing resources with fresh ones',                        :short => '-O', :type => :boolean",
      :report_metadata => "opt :report_metadata, 'Report metadata to SimpleDB',                                 :short => '-R', :type => :boolean",
      :report_tags     => "opt :report_tags, 'Additional tags to help database sorting (e.g. -T sprint28)',     :short => '-T', :type => :strings",
      :project         => "opt :project, 'Specify which collateral project to use',                             :short => '-P', :type => :string",

      :security_group_name  => "opt :security_group_name, 'Populate the file with this security group',                                 :short => :none,  :type => :string",
      :ssh_keys             => "opt :ssh_keys, 'Takes a JSON object of cloud ids mapped to ssh_key ids. (e.g. {1: 123456, 2: 789012})', :short => :none,  :type => :string",
      :api_version          => "opt :api_version, 'Check to see if the monkey has RightScale API access',                               :short => '-a',   :type => :float"
    }

    ConfigOptions = {
      "set"     => {"description" => "Set a configurable variable",
                    "usage"       => "'monkey config (-s|--set|set) <name> <value>'"},

      "edit"    => {"description" => "Open config file in your git editor",
                    "usage"       => "'monkey config (-e|--edit|edit)'"},

      "unset"   => {"description" => "Unset a configurable variable",
                    "usage"       => "'monkey config (-u|--unset|unset) <name>'"},

      "list"    => {"description" => "List current config variables",
                    "usage"       => "'monkey config (-l|--list|list)'"},

      "catalog" => {"description" => "List all possible configurable variables",
                    "usage"       => "'monkey config (-c|--catalog|catalog)'"},

      "get"     => {"description" => "Get the value of one variable",
                    "usage"       => "'monkey config (-g|--get|get) <name>'"},

      "help"    => {"description" => "Print this help message",
                    "usage"       => "'monkey config (-h|--help|help)'"}
    }

    ConfigVariables = {
      "test_permutation"    => {"description" => "Controls how individual test cases in a feature file get assigned per deployment",
                                "values"      => ["distributive", "exhaustive"]},

      "test_ordering"       => {"description" => "Controls how individual test cases in a feature file are ordered for execution",
                                "values"      => ["random", "strict"]},

      "feature_mixins"      => {"description" => "Controls how multiple features are distributed amongst available deployments",
                                "values"      => ["spanning", "parallel"]},

      "load_progress"       => {"description" => "Turns on/off the display of load progress info for 'monkey' commands",
                                "values"      => ["show", "hide"]},

      "colorized_text"      => {"description" => "Turns on/off colorized console text",
                                "values"      => ["show", "hide"]},

      "max_retries"         => {"description" => "Controls how many retries to attempt in a scope stack before giving up",
                                "values"      => Integer},

      "grinder_subprocess"  => {"description" => "Turns on/off the ability of Grinder to load into the current process",
                                "values"      => ["allow_same_process", "force_subprocess"]}
    }

    CollateralOptions = {
      "clone"     => {"description" => "Clone a remote repository into the local collateral",
                      "usage"       => "'monkey collateral (-c|--clone|clone) <repository> <project> [--bare] [--depth <i>]'"},

      "init"      => {"description" => "Create a new local collateral project",
                      "usage"       => "'monkey collateral (-i|--init|init) <project>'"},

      "checkout"  => {"description" => "Checkout a branch or paths to the working tree of the specified collateral project",
                      "usage"       => "'monkey collateral (-k|--checkout|checkout) <project> <name> [-f|--force]'"},

      "pull"      => {"description" => "Fetch from and merge with a local collateral project",
                      "usage"       => "'monkey collateral (-p|--pull|pull) <project> [<remote> [<branch>]]'"},

      "list"      => {"description" => "List the local collateral projects, origin repositories, and current branches",
                      "usage"       => "'monkey collateral (-l|--list|list)'"},

      "delete"    => {"description" => "Delete a local collateral project",
                      "usage"       => "'monkey collateral (-d|--delete|delete) <project>'"},

      "help"      => {"description" => "Print this help message",
                      "usage"       => "'monkey collateral (-h|--help|help)'"}
    }

    @@command_flags ||= {}

    def self.init(*args)
      # Monkey available_commands
      @@available_commands = AvailableCommands

      # QA available_commands
      @@available_qa_commands = AvailableQACommands

      @@flags = Flags

      @@version_string = "VirtualMonkey #{VirtualMonkey::VERSION}"

      # Regular message
      unless class_variable_defined?("@@usage_msg")
        @@usage_msg = "\nValid commands for #{@@version_string}:\n\n"
        @@usage_msg += pretty_help_message(@@available_commands)
        @@usage_msg += "\n\nHelp usage: 'monkey help <command>' OR 'monkey <command> --help'\n"
        @@usage_msg += "If this is your first time using VirtualMonkey, start with 'new_runner' and 'new_config'."
        @@usage_msg += " If you already have an example deployment, you can use 'import_deployment'.\n\n"
        @@usage_msg = word_wrap(@@usage_msg)
      end

      # QA Mode message
=begin
      unless class_variable_defined?("@@qa_usage_msg")
        @@qa_usage_msg = "\nValid commands for #{@@version_string} (QA mode):\n\n"
        @@qa_usage_msg += pretty_help_message(@@available_qa_commands)
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
      @@selected_project = nil
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

    def self.pretty_help_message(content_hash)
      double_spaced = false
      return "" if content_hash.empty?
      max_key_width = content_hash.keys.map { |k| k.to_s.length }.max
      remaining_width = (ENV["COLUMNS"] || `stty size`.chomp.split(/ /).last).to_i - (max_key_width + "  :   ".size + 2)
      key_format_string = "  %#{max_key_width}s:   "
      field_format_string = "%-#{remaining_width}s"
      base_format_string = key_format_string + field_format_string
      val_format_string = "#{" " * (max_key_width + 6)}#{field_format_string}"
      sorted_content_ary = content_hash.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
      message = []
      case content_hash.values.first
      when String
        message = sorted_content_ary.map do |k,v|
          ret = ""
          if v.size <= remaining_width
            ret = base_format_string % [k,v]
          else
            double_spaced = true
            wrapped_ary = word_wrap(v, remaining_width).split("\n")
            fmt_string = ([base_format_string] + ([val_format_string] * (wrapped_ary.size - 1))).join("\n")
            ret = fmt_string % ([k] + wrapped_ary)
          end
          ret
        end
      when Hash
        double_spaced = true
        message = sorted_content_ary.map do |k,v|
          fmt_string_ary = []
          wrapped_ary = []
          if v["description"]
            fmt_string_ary << base_format_string
            text = v["description"]
            if text.size <= remaining_width
              wrapped_ary << text
            else
              wrapped_val_ary = word_wrap(text, remaining_width).split("\n")
              fmt_string_ary += [val_format_string] * (wrapped_val_ary.size - 1)
              wrapped_ary += wrapped_val_ary
            end
          end
          v.keys.sort.each { |type|
            text = ""
            case type
            when "description" then next
            when "values", "origin", "branch" then text = "#{type.titlecase}: #{v[type].inspect}"
            when "usage" then text = "#{type.titlecase}: #{v[type]}"
            end
            if text.size <= remaining_width
              fmt_string_ary << val_format_string
              wrapped_ary << text
            else
              wrapped_val_ary = word_wrap(text, remaining_width).split("\n")
              fmt_string_ary += [val_format_string] * wrapped_val_ary.size
              wrapped_ary += wrapped_val_ary
            end
          }
          unless v["description"]
            fmt_string_ary.shift
            fmt_string_ary.unshift(field_format_string)
          end
          fmt_string = fmt_string_ary.join("\n")
          fmt_string = key_format_string + fmt_string unless v["description"]
          fmt_string % ([k] + wrapped_ary)
        end
      end
      (double_spaced ? message.join("\n\n") : message.join("\n"))
    end

    def self.word_wrap(txt, width=(ENV["COLUMNS"] || `stty size`.chomp.split(/ /).last).to_i)
      txt.gsub(/(.{1,#{width}})( +|$\n?)|(.{1,#{width}})/, "\\1\\3\n")
    end
  end
end

# Auto-require Section
automatic_require(VirtualMonkey::COMMAND_DIR)
