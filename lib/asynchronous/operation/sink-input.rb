module PulseAudio
  module Asynchronous
    class SinkInput
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA
        
        
        def move_to_sink!(sink, &b) # :yields: operation, success, user_data
          initialize_success_callback_handler              
          @block = b

          case sink
            when Fixnum
              pa_context_move_sink_input_by_index @parent.context.pointer, @parent.index, sink, @success_callback_handler, nil

            when String
              pa_context_move_sink_input_by_name @parent.context.pointer, @parent.index, sink, @success_callback_handler, nil

            when Sink
              pa_context_move_sink_input_by_index @parent.context.pointer, @parent.index, sink.index, @success_callback_handler, nil

          end
        end


        protected
          include Common::Callbacks


          attach_function :pa_context_move_sink_input_by_index, [ :pointer, :uint32, :uint32, :pa_context_success_cb_t, :pointer ], :pointer
          attach_function :pa_context_move_sink_input_by_name, [ :pointer, :uint32, :string, :pa_context_success_cb_t, :pointer ], :pointer

      end
    end    
  end
end

