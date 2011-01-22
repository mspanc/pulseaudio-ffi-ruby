module PulseAudio
  module Asynchronous
    class DaemonObject
      def method_missing(method, *arg)
        if respond_to? :operation and defined? "#{self.class}::Operation"
          if arg.size == 1 and self.class.const_get("Operation").instance_method(method).arity == 1
            operation.send(method, arg.first)
          elsif self.class.const_get("Operation").instance_method(method).arity == 0
            operation.send(method)
          else
            operation.send(method, arg)
          end
        else
          super
        end
      end
    end
  end
end