require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'

x=SharedDns.new("virtualmonkey_dyndns_new")
x.release_all
