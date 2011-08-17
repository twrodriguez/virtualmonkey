require 'rubygems'
require 'rest_connection'
require 'fog'
require 'fileutils'
require 'parse_tree'
require 'parse_tree_extensions'
require 'ruby2ruby'

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
end

require 'virtualmonkey/patches'
require 'virtualmonkey/deployment_monk'
require 'virtualmonkey/grinder_monk'
require 'virtualmonkey/shared_dns'
require 'virtualmonkey/message_check'
require 'virtualmonkey/test_case_interface'
require 'virtualmonkey/test_case_dsl'
require 'virtualmonkey/command'
require 'virtualmonkey/toolbox'
require 'virtualmonkey/runner_mixins'
require 'virtualmonkey/deployment_runners'
