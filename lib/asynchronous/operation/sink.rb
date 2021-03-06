module PulseAudio
  module Asynchronous
    class Sink
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA

        # Set this sink as default.
        def set_default!(&b) # :yields: operation, success, user_data
          initialize_success_callback_handler              
          @block = b
          
          pa_context_set_default_sink @parent.context.pointer, @parent.name, @success_callback_handler, nil          
        end

        # Find Module that is owner of this sink.
        def module(&b) # :yields: operation, module, user_data 
          raise ArgumentError, "You must pass a block to this function." unless block_given?
          
          @parent.context.operation.modules.find @parent.owner_module_index do |operation, mod, user_data|
            b.call operation, mod, user_data
          end
        end

        protected
          include Common::Callbacks
          
          attach_function :pa_context_set_default_sink, [ :pointer, :string, :pa_context_success_cb_t, :pointer ], :pointer

      end
    end    
  end
end

