module PulseAudio
  module Asynchronous
    class Sink < DaemonObject
      include Common::FlagsFunctions
      
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :operation, :context

      attr_reader :index, :name, :driver, :owner_module_index, :flags
      
      def initialize(operation, constructor) # :nodoc:
        @operation = operation
        @context = operation.parent

        if constructor.is_a? FFI::Pointer
          struct = Types::Structures::SinkInfo.new constructor
          @index = struct[:index]
          @name = struct[:name]
          @owner_module_index = struct[:owner_module]
          @driver = struct[:driver]
          @flags = parse_flags struct[:flags], { 0x0001 => :hw_volume_ctrl,
                                                 0x0002 => :latency,
                                                 0x0004 => :hardware,
                                                 0x0008 => :network,
                                                 0x0010 => :hw_mute_ctrl,
                                                 0x0020 => :decibel_volume,
                                                 0x0040 => :flat_volume,
                                                 0x0080 => :dynamic_latency }

#          @proplist = # TODO map to proplist structure          
        end
      end
      
      # Return a new Sink::Operation object.
      #
      # You can use returned object to perform asynchronous tasks on this sink.
      #
      # Please read the wiki[https://github.com/saepia/pulseaudio-ffi-ruby/wiki/Documentation-examples] for more information about this syntax.
      def operation(options = nil)
        Operation.new self, options
      end      
      
      
      def inspect # :nodoc:
        "#<#{self.class} ##{index} \"#{name}\">"
      end

    end  
    
    
    
    class Sinks      
      extend FFI::Library
      ffi_lib LIB_PA

      include Common::Callbacks
      include Common::QueryFunctions

      
      attr_reader :operation
      
      def initialize(operation) # :nodoc:
        @operation = operation
      end
      
      # Get list of all available sinks.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +list+ is an array of PulseAudio::Asynchronous::Sink objects found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def all(&b) # :yields: operation, list, user_data
        @block = b
        
        initialize_sink_info_list_callback_handler
        pa_context_get_sink_info_list @operation.parent.pointer, @sink_info_list_callback_handler, nil
      end


      protected
        callback :pa_sink_info_cb_t, [ :pointer, ::PulseAudio::Asynchronous::Types::Structures::SinkInfo, :int, :pointer ], :void
        attach_function :pa_context_get_sink_info_list, [ :pointer, :pa_sink_info_cb_t, :pointer ], :pointer
        
        def initialize_sink_info_list_callback_handler # :nodoc:
          initialize_list
          unless @sink_info_list_callback_handler
            @sink_info_list_callback_handler = Proc.new{ |context, sink_info, eol, user_data|
              if eol != 1
                @list << Sink.new(@operation, sink_info)
              else
                callback.call @operation, @list, @operation.user_data if callback
              end
            }
          end
        end           
    end    
  end
end
