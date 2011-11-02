module VirtualMonkey
  module Mixin
    module MonkeyDiagnostic
      extend VirtualMonkey::RunnerCore::CommandHooks

      def load_inputs
        s = VirtualMonkey::my_api_self
        if s.multicloud && s.current_instance
          s.current_instance.inputs.each { |hsh|
            @my_inputs[hsh["name"]] = hsh["value"]
          }
        elsif s.current_instance_href
          s.reload_as_current
          s.settings
          s.parameters.each { |input_name,input_value|
            @my_inputs[input_name] = input_value
          }
          s.reload_as_next
        end
      end

    end
  end
end
