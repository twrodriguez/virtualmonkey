require 'yaml'

module VirtualMonkey
  ROOTDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
  CONFIG_DIR = File.join(ROOTDIR, "config")
  TEST_STATE_DIR = File.join(ROOTDIR, "test_states")
  FEATURE_DIR = File.join(ROOTDIR, "features")
  LIB_DIR = File.join(ROOTDIR, "lib", "virtualmonkey")
  COMMAND_DIR = File.join(LIB_DIR, "command")
  RUNNER_DIR = File.join(LIB_DIR, "deployment_runners")
  MIXIN_DIR = File.join(LIB_DIR, "runner_mixins")
  CLOUD_VAR_DIR = File.join(CONFIG_DIR, "cloud_variables")
  COMMON_INPUT_DIR = File.join(CONFIG_DIR, "common_inputs")
  TROOP_DIR = File.join(CONFIG_DIR, "troop")
  LIST_DIR = File.join(CONFIG_DIR, "lists")
  WEB_APP_DIR = File.join(ROOTDIR, "lib", "spidermonkey")

  @@rest_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml")
  @@rest_yaml = File.join("", "etc", "rest_connection", "rest_api_config.yaml") unless File.exists?(@@rest_yaml)
  REST_YAML = @@rest_yaml

  branch = (`git branch 2> /dev/null | grep \\*`.chomp =~ /\* ([^ ]+)/; $1) || "master"
  VERSION = (`cat "#{File.join(ROOTDIR, "VERSION")}"`.chomp + (branch == "master" ? "" : " #{branch.upcase}"))

  ROOT_CONFIG = File.join(VirtualMonkey::ROOTDIR, ".config.yaml")
  USER_CONFIG = File.join(File.expand_path("~"), ".virtualmonkey", "config.yaml")
  SYS_CONFIG = File.join("", "etc", "virtualmonkey", "config.yaml")

  def self.config
    @@virtual_monkey_config = {}
    [VirtualMonkey::SYS_CONFIG, VirtualMonkey::USER_CONFIG, VirtualMonkey::ROOT_CONFIG].each do |config_file|
      if File.exists?(config_file)
        @@virtual_monkey_config.merge!(YAML::load(IO.read(config_file)) || {})
        if VirtualMonkey.const_defined?("Command")
          config_ok = @@virtual_monkey_config.reduce(true) do |bool,ary|
            bool && VirtualMonkey::Command::check_variable_value(ary[0], ary[1])
          end
          warn "WARNING: #{config_file} contains an invalid variable or value" unless config_ok
        end
      end
    end
    @@virtual_monkey_config
  end
end

def progress_require(file, progress=nil)
  if VirtualMonkey::config[:load_progress] != "hide"
    @current_progress ||= nil
    if ENV['ENTRY_COMMAND'] == "monkey" && progress && progress != @current_progress
      STDOUT.print "\nloading #{progress}"
    end
    @current_progress = progress || @current_progress
  end
  STDOUT.flush

  ret = require file

  if VirtualMonkey::config[:load_progress] != "hide"
    if ENV['ENTRY_COMMAND'] == "monkey" && ret
      STDOUT.print "."
    end
  end
  STDOUT.flush
  ret
end

def automatic_require(full_path, progress=nil)
  some_not_included = true
  files = Dir.glob(File.join(File.expand_path(full_path), "**"))
  retry_loop = 0
  while some_not_included and retry_loop < (files.size ** 2) do
    begin
      some_not_included = false
      for f in files do
        val = progress_require(f.chomp(".rb"), progress) if f =~ /\.rb$/
        some_not_included ||= val
      end
    rescue NameError => e
      raise e unless "#{e}" =~ /uninitialized constant/i
      some_not_included = true
      files.push(files.shift)
    end
    retry_loop += 1
  end
end

progress_require('rubygems', 'dependencies')
progress_require('rest_connection')
progress_require('right_popen')
progress_require('fog')
progress_require('fileutils')
progress_require('parse_tree')
progress_require('parse_tree_extensions')
progress_require('ruby2ruby')
progress_require('colorize')

progress_require('virtualmonkey/patches', 'virtualmonkey')
progress_require('virtualmonkey/deployment_monk')
progress_require('virtualmonkey/grinder_monk')
progress_require('virtualmonkey/shared_dns')
progress_require('virtualmonkey/message_check')
progress_require('virtualmonkey/test_case_interface')
progress_require('virtualmonkey/test_case_dsl')

progress_require('virtualmonkey/command', 'commands')
progress_require('virtualmonkey/toolbox')

progress_require('virtualmonkey/runner_mixins', 'mixins')

progress_require('virtualmonkey/deployment_runners', 'runners')

progress_require('spidermonkey.rb', 'spidermonkey')
puts "\n"
VirtualMonkey::config
