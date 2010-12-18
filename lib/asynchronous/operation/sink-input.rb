module PulseAudio
  module Asynchronous
    class SinkInput
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA
        
        # Move the specified sink input to a different sink.
        #
        # +sink+ is Fixnum, String or Sink - depends whether you want to identify sink by its index, name or just pass existing Sink object (which internally results in identyfying via its index, but gives clearer syntax in certain cases)
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
        
        # Set the mute switch of a sink input stream.
        #
        # +muted+ is boolean value
        def muted=(muted, &b) # :yields: operation, success, user_data
          initialize_success_callback_handler              
          @block = b
          
          pa_context_set_sink_input_mute @parent.context.pointer, @parent.index, muted == true ? 1 : 0, @success_callback_handler, nil
        end


        protected
          include Common::Callbacks


          attach_function :pa_context_move_sink_input_by_index, [ :pointer, :uint32, :uint32, :pa_context_success_cb_t, :pointer ], :pointer
          attach_function :pa_context_move_sink_input_by_name, [ :pointer, :uint32, :string, :pa_context_success_cb_t, :pointer ], :pointer
          attach_function :pa_context_set_sink_input_mute, [ :pointer, :uint32, :int, :pa_context_success_cb_t, :pointer ], :pointer

      end
    end    
  end
end

