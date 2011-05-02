#@base
#
# Feature: Base Server Test
#   Tests the base server functions
#
# Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::MonkeySelfTestRunner.new(ENV['DEPLOYMENT'])
  bla = "imanarray"
  ball = [bla, bla, bla, bla, bla ,bla, bla]
  @runner.behavior(:function3, ball)
  @runner.behavior(:function3, ball)
  #@runner.behavior(:function3)
      set = ["g1","u2","r3","u4"]
  command1 =  "probe from feature"
     @runner.probe(set,command1)
  @runner.behavior(:function3, ball)
  @runner.behavior(:function3, ball)
  #return "hello"     
 # @runner.behavior(:function4)
