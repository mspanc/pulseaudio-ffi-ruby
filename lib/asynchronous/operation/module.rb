module PulseAudio
  module Asynchronous
    class Module
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA
        
        # Unload this module.
        def unload!(&b) # :yields: operation, success, user_data
          initialize_success_callback_handler              
          @block = b

          pa_context_unload_module @parent.context.pointer, @parent.index, @success_callback_handler, nil
        end
        
        # Find Sink associated with this module.
        def sink(&b) # :yields: operation, sink, user_data 
          # TODO
        end

        protected
          include Common::Callbacks

          attach_function :pa_context_unload_module, [ :pointer, :uint32, :pa_context_success_cb_t, :pointer ], :pointer

      end
    end    
  end
end

