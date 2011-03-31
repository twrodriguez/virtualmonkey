#@base
#
# Feature: Base Server Test
#   Tests the base server functions
#
# Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::SimpleRunner.new(ENV['DEPLOYMENT'])

# Then I should test a failing script
  @runner.behavior(:run_script_on_all, "test", true, {"EXIT_VAL" => "text:1"}) { |res| res.is_a?(Exception) }
