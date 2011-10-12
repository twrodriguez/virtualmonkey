STDERR.print "loading dependencies" if ENV['ENTRY_COMMAND'] == "monkey"
require 'rubygems'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'rest_connection'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'right_popen'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'fog'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'fileutils'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'parse_tree'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'parse_tree_extensions'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'ruby2ruby'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'colorize'


STDERR.print "\nloading virtualmonkey" if ENV['ENTRY_COMMAND'] == "monkey"

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
  WEB_APP_DIR = File.join(ROOTDIR, "lib", "web_app")

  @@rest_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml")
  @@rest_yaml = File.join("", "etc", "rest_connection", "rest_api_config.yaml") unless File.exists?(@@rest_yaml)
  REST_YAML = @@rest_yaml

  branch = (`git branch 2> /dev/null | grep \\*`.chomp =~ /\* ([^ ]+)/; $1) || "master"
  VERSION = (`cat "#{File.join(ROOTDIR, "VERSION")}"`.chomp + (branch == "master" ? "" : " #{branch.upcase}"))

  def self.auto_require(full_path)
    some_not_included = true
    files = Dir.glob(File.join(File.expand_path(full_path), "**"))
    retry_loop = 0
    while some_not_included and retry_loop < (files.size ** 2) do
      begin
        some_not_included = false
        for f in files do
          val = require f.chomp(".rb") if f =~ /\.rb$/
          STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey" && val
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
end


STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/patches'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/deployment_monk'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/grinder_monk'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/shared_dns'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/message_check'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/test_case_interface'

STDERR.print "." if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/test_case_dsl'

STDERR.print "\nloading commands" if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/command'
require 'virtualmonkey/toolbox'

STDERR.print "\nloading mixins" if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/runner_mixins'

STDERR.print "\nloading runners" if ENV['ENTRY_COMMAND'] == "monkey"
require 'virtualmonkey/deployment_runners'

STDERR.print "\nloading web_app..." if ENV['ENTRY_COMMAND'] == "monkey"
require 'web_app.rb'

STDERR.print "\nComplete!\n" if ENV['ENTRY_COMMAND'] == "monkey"
