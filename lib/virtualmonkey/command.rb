#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require 'highline/import'
require 'uri'
require 'pp'

# Auto-require Section
some_not_included = true
files = Dir.glob(File.join(VirtualMonkey::COMMAND_DIR, "**"))
retry_loop = 0
while some_not_included and retry_loop < (files.size ** 2) do
  begin
    some_not_included = false
    for f in files do
      some_not_included ||= require f.chomp(".rb") if f =~ /\.rb$/
    end
  rescue NameError => e
    raise e unless e.message =~ /uninitialized constant/i
    some_not_included = true
    files.push(files.shift)
  end
  retry_loop += 1
end

module VirtualMonkey
  module Command
    AvailableCommands = {
      :api_check                  => "Verify API version connectivity",
      :clone                      => "Clone a deployment n times and run though feature tests",
      :create                     => "Create MCI and Cloud permutation Deployments for a set of ServerTemplates",
      :destroy                    => "Destroy a set of Deployments",
      :destroy_ssh_keys           => "Destroy VirtualMonkey-generated SSH Keys",
      :generate_ssh_keys          => "Generate SSH Key files per Cloud and stores their hrefs in ssh_keys.json",
      :import_deployment          => "Import an existing Deployment and create a new testing scenario for it",
      :list                       => "List the full Deployment nicknames and Server statuses for a set of Deployments",
      :new_config                 => "Interactively create a new Troop Config JSON File",
      :new_runner                 => "Interactively create a new testing scenario and all necessary files",
      :populate_all_cloud_vars    => "Calls 'generate_ssh_keys', 'populate_datacenters', and 'populate_security_groups' for all Clouds",
      :populate_datacenters       => "Populates datacenters.json with API 1.5 hrefs per Cloud",
      :populate_security_groups   => "Populates security_groups.json with appropriate hrefs per Cloud",
      :run                        => "Execute a set of feature tests across a set of Deployments in parallel",
      :troop                      => "Calls 'create', 'run', and 'destroy' for a given troop config file",
      :update_inputs              => "Updates the inputs and editable server parameters for a set of Deployments",
      :version                    => "Displays version and exits",
      :help                       => "Displays usage information"
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
      :terminate      => "opt :terminate, 'Terminate if tests successfully complete. (No destroy)',         :short => '-a', :type => :boolean",
      :common_inputs  => "opt :common_inputs, 'Input JSON files to be set at Deployment AND Server levels', :short => '-c', :type => :strings",
      :deployment     => "opt :deployment, 'regex string to use for matching deployment',                   :short => '-d', :type => :string",
      :config_file    => "opt :config_file, 'Troop Config JSON File',                                       :short => '-f', :type => :string",
      :clouds         => "opt :clouds, 'Space-separated list of cloud_ids to use',                          :short => '-i', :type => :integers",
      :keep           => "opt :keep, 'Do not delete servers or deployments after terminating',              :short => '-k', :type => :boolean",
      :use_mci        => "opt :use_mci, 'List of MCI hrefs to substitute for the ST-attached MCIs',         :short => '-m', :type => :string, :multi => true",
      :n_copies       => "opt :n_copies, 'Number of clones to make',                                        :short => '-n', :type => :integer, :default => 1",
      :only           => "opt :only, 'Regex string to use for subselection matching on MCIs',               :short => '-o', :type => :string",
      :no_spot        => "opt :no_spot, 'do not use spot instances',                                        :short => '-p', :type => :boolean, :default => true",
      :no_resume      => "opt :no_resume, 'Do not use trace info to resume a previous test',                :short => '-r', :type => :boolean",
      :tests          => "opt :tests, 'List of test names to run across Deployments (default is all)',      :short => '-t', :type => :strings",
      :verbose        => "opt :verbose, 'Print all output to STDOUT as well as the log files',              :short => '-v', :type => :boolean",
      :prefix         => "opt :prefix, 'Prefix of the Deployments',                                         :short => '-x', :type => :string",
      :yes            => "opt :yes, 'Turn off confirmation',                                                :short => '-y', :type => :boolean",
      :one_deploy     => "opt :one_deploy, 'Load all variations of a single ST into one Deployment',        :short => '-z', :type => :boolean"
    }

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
      @@usage_msg = "\nValid commands for #{@@version_string}:\n\n"
      max_width = @@available_commands.keys.map { |k| k.to_s.length }.max
      @@usage_msg += @@available_commands.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }.map { |k,v| "  %#{max_width}s:   #{v}" % k }.join("\n")
      @@usage_msg += "\n\nHelp usage: 'monkey help <command>' OR 'monkey <command> --help'\n"
      @@usage_msg += "If this is your first time using VirtualMonkey, start with new_runner and new_config\n\n"

      # QA Mode message
      @@qa_usage_msg = "\nValid commands for #{@@version_string} (QA mode):\n\n"
      qa_max_width = @@available_qa_commands.keys.map { |k| k.to_s.length }.max
      @@qa_usage_msg += @@available_qa_commands.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }.map { |k,v| "  %#{qa_max_width}s:   #{v}" % k }.join("\n")
      @@qa_usage_msg += "\n\nHelp usage: 'qa help <command>' OR 'qa <command> --help'\n\n"

      # Parse any passed args and put them in ARGV if they exist
      if args.length > 1
        ARGV.replace args
      elsif args.length == 1
        ARGV.replace args.first.split(/ /)
      end
    end

    # Parses the initial command string, removing it from ARGV, then runs command.
    def self.go(*args)
      self.init(*args)
      @@command = ARGV.shift
      if @@available_commands[@@command.to_sym]
        VirtualMonkey::Command.__send__(@@command)
      elsif @@command == "-h" or @@command == "--help"
        VirtualMonkey::Command.help
      else
        STDERR.puts "Invalid command #{@@command}\n\n#{@@usage_msg}"
        exit(1)
      end
    end

    def self.use_options(*args)
      ret = args.sort { |a,b| a.to_s <=> b.to_s }.map { |op| @@flags[op] }
#      ret << "version '#{VirtualMonkey::VERSION}'"
      return ret.join(";")
    end

    # Help command
    def self.help(*args)
      self.init(*args)
      if subcommand = ARGV.shift
        ENV['REST_CONNECTION_LOG'] = "/dev/null"
        VirtualMonkey::Command.__send__(subcommand, "--help")
      else
        puts @@usage_msg
      end
    end

    # Version command
    def self.version(*args)
      self.init(*args)
      puts @@version_string
    end
  end
end
