module PulseAudio
  module Asynchronous
    # DaemonObject class is proxy class for all classes that represents PulseAudio objects.
    #
    # Currently it is used only to shorten the syntax. Thanks to ruby's method_missing
    # you can call e.g.
    #
    # context.sinks.all do |...|
    #
    # instead of
    # 
    # context.operation.sinks.all do |...|
    #
    # What cuts "operation" call is this class. You can find more information about 
    # the syntax in the project's wiki[https://github.com/saepia/pulseaudio-ffi-ruby/wiki].
    class DaemonObject
      def method_missing(method, *arg, &b)
        if respond_to? :operation and defined? "#{self.class}::Operation"
          if block_given?
            if arg.size == 1 and self.class.const_get("Operation").instance_method(method).arity == 1
              operation.send(method, arg.first, &b)
            elsif self.class.const_get("Operation").instance_method(method).arity == 0
              operation.send(method, &b)
            else
              operation.send(method, arg, &b)
            end
          else
            if arg.size == 1 and self.class.const_get("Operation").instance_method(method).arity == 1
              operation.send(method, arg.first)
            elsif self.class.const_get("Operation").instance_method(method).arity == 0
              operation.send(method)
            else
              operation.send(method, arg)
            end
          end
        else
          super
        end
      end
    end
  end
end
