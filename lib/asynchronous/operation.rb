module PulseAudio
  module Asynchronous
    class Operation
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :parent, :pointer, :callback_proc, :user_data

      def initialize(parent, options = {}) # :nodoc:
        @parent = parent

        if options
          @user_data = options[:user_data]
          @callback_proc = options[:callback_proc]
        end

        @pointer = nil
      end

      # Return the current status of the operation.
      #
      # Valid return values are :running, :done, :cancelled.
      def state
        raise Errors::NotPerformedYetError, "You must perform some action first on this PulseAudio::Operation object to check its state" unless @pointer
        
        pa_operation_get_state @pointer
      end
      
      # Cancel the operation.
      #
      # Beware! This will not necessarily cancel the execution of the operation on the server side. 
      # However it will make sure that the callback associated with this operation will not be called 
      # anymore, effectively disabling the operation from the client side's view.
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
