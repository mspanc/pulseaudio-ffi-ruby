module PulseAudio
  module Asynchronous
    class Client
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA

        include Common::Callbacks

        def kill!(&b)
          @block = b
          initialize_success_callback_handler
          pa_context_kill_client @parent.context.pointer, @parent.index, @success_callback_handler, nil
        end
              
        protected
          attach_function :pa_context_kill_client, [ :pointer, :uint32, :pa_context_success_cb_t, :pointer ], :pointer

      end
    end    
  end
end

