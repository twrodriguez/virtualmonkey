module VirtualMonkey
  module Mixin
    module Chef
      extend VirtualMonkey::Mixin::CommandHooks
      def chef_download_once_lookup_scripts
       # @servers.each { |s| s.add_tags("rs_agent_dev:download_cookbooks_once=true") }
      end
    end
  end
end
