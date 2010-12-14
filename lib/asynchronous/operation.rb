module PulseAudio
  module Asynchronous
    class Operation
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :context, :pointer, :callback_proc, :user_data

      def initialize(context, options = {})
        @context = context

        if options
          @user_data = options[:user_data]
          @callback_proc = options[:callback_proc]
        end

        @pointer = nil
      end

      def state
        raise ::PulseAudio::Asynchronous::Errors::OperationNotPerformedYetError, "You must perform some action first on this PulseAudio::Operation object to check its state" unless @pointer
        
        pa_operation_get_state @pointer
      end
      
      def cancel!
        pa_operation_cancel @pointer
        nil
      end    
      
      
      protected
        include Common::Callbacks
        attach_function :pa_operation_get_state, [ :pointer ], Types::Enums::OperationState
        attach_function :pa_operation_cancel, [ :pointer ], :void
      
    end
  end
end
