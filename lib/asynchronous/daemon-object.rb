module PulseAudio
  module Asynchronous
    class DaemonObject
      def method_missing(method, *arg)
        if respond_to? :operation and defined? "#{self.class}::Operation"
          if arg.size == 1
            operation.send(method, arg.first)
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
