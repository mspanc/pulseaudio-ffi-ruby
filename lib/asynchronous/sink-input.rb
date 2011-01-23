module PulseAudio
  module Asynchronous
    class SinkInput < DaemonObject
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :operation, :context

      attr_reader :index, :name, :owner_module_index, :client_index, :sink_index,
                  :sample_spec, :channel_map, :volume, :buffer_usec, :sink_usec,
                  :resample_method, :driver, :proplist
      
      def initialize(operation, constructor) # :nodoc:
        @operation = operation
        @context = operation.parent

        if constructor.is_a? FFI::Pointer
          struct = Types::Structures::SinkInputInfo.new constructor

          @index = struct[:index]
          @name = struct[:name]
          @owner_module_index = struct[:owner_module]
          @client_index = struct[:client]
          @sink_index = struct[:sink]
          @sample_spec = struct[:sample_spec]
          @channel_map = struct[:channel_map]
          @volume = struct[:volume]
          @buffer_usec = struct[:buffer_usec]
          @sink_usec = struct[:sink_usec]
          @resample_method = struct[:resample_method]
          @driver = struct[:driver]
          @mute = struct[:mute]
          @proplist = PropList.new struct[:proplist]
          
        end
      end
      
      # Returns true if sink input is muted
      def muted?
        @mute == 1
      end
      
      # Return a new SinkInput::Operation object.
      #
      # You can use returned object to perform asynchronous tasks on this sink input.
      #
      # Please read the wiki[https://github.com/saepia/pulseaudio-ffi-ruby/wiki/Documentation-examples] for more information about this syntax.
      def operation(options = nil)
        Operation.new self, options
      end      
      
      def inspect # :nodoc:
        "#<#{self.class} ##{index} \"#{name}\">"
      end
    end  
    
    
    
    class SinkInputs      
      extend FFI::Library
      ffi_lib LIB_PA

      include Common::Callbacks
      include Common::QueryFunctions

      
      attr_reader :operation
      
      def initialize(operation) # :nodoc:
        @operation = operation
      end
      
      # Get list of all available sink inputs.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +list+ is an array of PulseAudio::Asynchronous::SinkInputs objects found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def all(&b) # :yields: operation, list, user_data
        @block = b
        
        initialize_sink_input_info_list_callback_handler
        pa_context_get_sink_input_info_list @operation.parent.pointer, @sink_input_info_list_callback_handler, nil
      end

      # Get particular sink-input connected to the PulseAudio server identified by its index.
      #
      # +seek+ is a Fixnum containing sink input's ID.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +sink_input+ is PulseAudio::Asynchronous::SinkInput found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def find(seek, &b) # :yields: operation, sink_input, user_data
        @block = b

        case seek
          when Fixnum
            initialize_sink_input_info_callback_handler
            pa_context_get_sink_input_info @operation.parent.pointer, seek, @sink_input_info_callback_handler, nil
            
          else
            raise ArgumentError, "Argument passed to PulseAudio::Asynchronous::Clients::find has to be Fixnum"
        end
      end

      protected
        callback :pa_sink_input_info_cb_t, [ :pointer, ::PulseAudio::Asynchronous::Types::Structures::SinkInputInfo, :int, :pointer ], :void
        attach_function :pa_context_get_sink_input_info_list, [ :pointer, :pa_sink_input_info_cb_t, :pointer ], :pointer
        attach_function :pa_context_get_sink_input_info, [ :pointer, :uint32, :pa_sink_input_info_cb_t, :pointer ], :pointer
        
        def initialize_sink_input_info_callback_handler # :nodoc:
          unless @sink_input_info_callback_handler
            @sink_input_info_callback_handler = Proc.new{ |context, sink_input_info, eol, user_data| 
              sink_input = sink_input_info.null? ? nil : SinkInput.new(@operation, sink_input_info)
              callback.call(@operation, sink_input, @operation.user_data) if callback unless eol == 1
            }
          end
        end      
        
        def initialize_sink_input_info_list_callback_handler # :nodoc:
          initialize_list
          unless @sink_input_info_list_callback_handler
            @sink_input_info_list_callback_handler = Proc.new{ |context, sink_input_info, eol, user_data|
              if eol != 1
                @list << SinkInput.new(@operation, sink_input_info)
              else
                callback.call @operation, @list, @operation.user_data if callback
              end
            }
          end
        end           
    end    
  end
end
