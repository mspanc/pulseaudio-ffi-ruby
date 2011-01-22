module PulseAudio
  module Asynchronous
    class SourceOutput < DaemonObject
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :operation, :context

      attr_reader :index, :name, :driver, :owner_module_index
      
      def initialize(operation, constructor) # :nodoc:
        @operation = operation
        @context = operation.parent

        if constructor.is_a? FFI::Pointer
          struct = Types::Structures::SourceOutputInfo.new constructor
          @index = struct[:index]
          @name = struct[:name]
          @owner_module_index = struct[:owner_module]
          @driver = struct[:driver]
#          @proplist = # TODO map to proplist structure          
        end
      end
      
      # Return a new SourceOutput::Operation object.
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
    
    
    
    class SourceOutputs      
      extend FFI::Library
      ffi_lib LIB_PA

      include Common::Callbacks
      include Common::QueryFunctions

      
      attr_reader :operation
      
      def initialize(operation) # :nodoc:
        @operation = operation
      end
      
      # Get list of all available source outputs.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +list+ is an array of PulseAudio::Asynchronous::SourceOutputs objects found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def all(&b) # :yields: operation, list, user_data
        @block = b
        
        initialize_source_output_info_list_callback_handler
        pa_context_get_source_output_info_list @operation.parent.pointer, @source_output_info_list_callback_handler, nil
      end


      protected
        callback :pa_source_output_info_cb_t, [ :pointer, ::PulseAudio::Asynchronous::Types::Structures::SourceOutputInfo, :int, :pointer ], :void
        attach_function :pa_context_get_source_output_info_list, [ :pointer, :pa_source_output_info_cb_t, :pointer ], :pointer
        
        def initialize_source_output_info_list_callback_handler # :nodoc:
          initialize_list
          unless @source_output_info_list_callback_handler
            @source_output_info_list_callback_handler = Proc.new{ |context, source_output_info, eol, user_data|
              if eol != 1
                @list << SourceOutput.new(@operation, source_output_info)
              else
                callback.call @operation, @list, @operation.user_data if callback
              end
            }
          end
        end           
    end    
  end
end
