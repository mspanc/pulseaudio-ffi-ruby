module PulseAudio
  module Asynchronous
    class Source < DaemonObject
      include Common::FlagsFunctions
      
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :operation, :context

      attr_reader :index, :name, :description, :sample_spec, :channel_map, :volume,
                  :mute, :monitor_sink_index, :monitor_sink_name, :latency, :configured_latency,
                  :driver, :base_volume, :state, :n_volume_steps, :card_index, :n_ports,
                  :owner_module_index, :flags, :proplist   
                     
      def initialize(operation, constructor) # :nodoc:
        @operation = operation
        @context = operation.parent


        if constructor.is_a? FFI::Pointer
          struct = Types::Structures::SourceInfo.new constructor
          
          @index = struct[:index]
          @name = struct[:name]
          @description = struct[:description]
          @sample_spec = struct[:sample_spec]
          @channel_map = struct[:channel_map]
          @owner_module_index = struct[:owner_module]
          @volume = struct[:volume]
          @mute = struct[:mute]
          @monitor_sink_index = struct[:monitor_of_sink]
          @monitor_sink_name = struct[:monitor_of_sink_name]
          @latency = struct[:latency]
          @configured_latency = struct[:configured_latency]
          @base_volume = struct[:base_volume]
          @state = struct[:state]
          @n_volume_steps = struct[:n_volume_steps]
          @card_index = struct[:card]
          @n_ports = struct[:n_ports]
#          @ports = 
#          @active_port = 
          @driver = struct[:driver]
          @flags = parse_flags struct[:flags], { 0x0001 => :hw_volume_ctrl,
                                                 0x0002 => :latency,
                                                 0x0004 => :hardware,
                                                 0x0008 => :network,
                                                 0x0010 => :hw_mute_ctrl,
                                                 0x0020 => :decibel_volume,
                                                 0x0040 => :dynamic_latency }          
                                                 
          @proplist = PropList.new struct[:proplist]
        end
      end
      
      # Return a new Source::Operation object.
      #
      # You can use returned object to perform asynchronous tasks on this source.
      #
      # Please read the wiki[https://github.com/saepia/pulseaudio-ffi-ruby/wiki/Documentation-examples] for more information about this syntax.
      def operation(options = nil)
        Operation.new self, options
      end      
      
      
      def inspect # :nodoc:
        "#<#{self.class} ##{index} \"#{name}\">"
      end
    end  
    
    
    
    class Sources      
      extend FFI::Library
      ffi_lib LIB_PA

      include Common::Callbacks
      include Common::QueryFunctions

      
      attr_reader :operation
      
      def initialize(operation) # :nodoc:
        @operation = operation
      end
      
      # Get list of all available sources.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +list+ is an array of PulseAudio::Asynchronous::Source objects found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def all(&b) # :yields: operation, list, user_data
        @block = b
        
        initialize_source_info_list_callback_handler
        pa_context_get_source_info_list @operation.parent.pointer, @source_info_list_callback_handler, nil
      end


      protected
        callback :pa_source_info_cb_t, [ :pointer, ::PulseAudio::Asynchronous::Types::Structures::SourceInfo, :int, :pointer ], :void
        attach_function :pa_context_get_source_info_list, [ :pointer, :pa_source_info_cb_t, :pointer ], :pointer
        
        def initialize_source_info_list_callback_handler # :nodoc:
          initialize_list
          unless @source_info_list_callback_handler
            @source_info_list_callback_handler = Proc.new{ |context, source_info, eol, user_data|
              if eol != 1
                @list << Source.new(@operation, source_info)
              else
                callback.call @operation, @list, @operation.user_data if callback
              end
            }
          end
        end           
    end    
  end
end
