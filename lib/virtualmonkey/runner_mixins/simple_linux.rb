module VirtualMonkey
  module Mixin
    module SimpleLinux

      def swapspace_fe_lookup_scripts
        scripts = [

                  ]
        st = ServerTemplate.find(104181)
        load_script_table(st,scripts)
      end


      def set_variation_swap_size(size_to_set)
        servers.first.set_input("sys/swap_size", "text:#{size_to_set}")
      end

      def test_swapspace
        probe(servers.first, "grep -c /swapfile /proc/swaps") { |result, status|
          print "grep -c /swapfile /proc/swaps returned = " + result.to_s
          raise "raise swap file not setup correctly" unless (Integer(result) > 0)
          true
        }
      end

    end
  end
end
