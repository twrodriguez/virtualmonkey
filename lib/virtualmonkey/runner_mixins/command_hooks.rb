module VirtualMonkey
  module Mixin
    module CommandHooks
      #
      # Monkey Create/Destroy API Hooks
      #

      def before_create(*args, &block)
        @@before_create ||= []
        @@before_create |= args
        @@before_create << block if block_given?
        @@before_create
      end

      def before_destroy(*args, &block)
        @@before_destroy ||= []
        @@before_destroy |= args
        @@before_destroy << block if block_given?
        @@before_destroy
      end

      def after_create(*args, &block)
        @@after_create ||= []
        @@after_create |= args
        @@after_create << block if block_given?
        @@after_create
      end

      def after_destroy(*args, &block)
        @@after_destroy ||= []
        @@after_destroy |= args
        @@after_destroy << block if block_given?
        @@after_destroy
      end

      def description(desc="")
        @@description ||= desc
        raise "FATAL: Description must be a string" unless @@description.is_a?(String)
        @@description
      end

      def assert_integrity!
        self.before_create.each { |fn|
          if not fn.is_a?(Proc)
            raise "FATAL: #{self.to_s} does not have a class method named #{fn}; before_create requires class methods" unless self.respond_to?(fn)
          end
        }
      end
    end
  end
end
