module PulseAudio
  module Asynchronous
    class Client < DaemonObject
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :index, :name, :owner_module, :driver, :proplist, :operation, :context
      
      def initialize(operation, constructor) # :nodoc:
        @operation = operation
        @context = operation.parent
        
        if constructor.is_a? FFI::Pointer
          struct = Types::Structures::ClientInfo.new constructor
          @index = struct[:index]
          @name = struct[:name]
#          @owner_module = struct[:name] # TODO - map to Module class
          @driver = struct[:driver]
#          @proplist = # TODO map to proplist structure          
        end
      end
      
      # Return a new Client::Operation object.
      #
      # You can use returned object to perform asynchronous tasks on this client.
      #
      # Please read the wiki[https://github.com/saepia/pulseaudio-ffi-ruby/wiki/Documentation-examples] for more information about this syntax.
      def operation(options = nil)
        Operation.new self, options
      end      
      
      
      def inspect # :nodoc:
        "#<#{self.class} ##{index} \"#{name}\">"
      end
    end  
    
    
    
    class Clients      
      extend FFI::Library
      ffi_lib LIB_PA

      include Common::Callbacks
      include Common::QueryFunctions

      
      attr_reader :operation
      
      def initialize(operation) # :nodoc:
        @operation = operation
      end
      
      # Get list of all clients connected to the PulseAudio server.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +list+ is an array of PulseAudio::Asynchronous::Client objects found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def all(&b) # :yields: operation, list, user_data
        @block = b
        
        initialize_client_info_list_callback_handler
        pa_context_get_client_info_list @operation.parent.pointer, @client_info_list_callback_handler, nil
      end

      # Get particular client connected to the PulseAudio server identified by its index or name.
      #
      # +seek+ is a Fixnum (if you seek by client's ID) or String (if you seek by client's name).
      #
      # Seeking via name internally calls function similar to all, so please note that it can be less 
      # efficient than seeking by ID.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +client+ is PulseAudio::Asynchronous::Client found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def find(seek, &b) # :yields: operation, client, user_data
        @block = b

        case seek
          when Fixnum
            initialize_client_info_callback_handler
            pa_context_get_client_info @operation.parent.pointer, seek, @client_info_callback_handler, nil
          
          when String
            initialize_client_info_list_name_seek_callback_handler
            @name_seek = seek
            pa_context_get_client_info_list @operation.parent.pointer, @client_info_list_name_seek_callback_handler, nil
            
          else
            raise ArgumentError, "Argument passed to PulseAudio::Asynchronous::Clients::[] has to be Fixnum or String"
        end
      end

      protected
        def initialize_client_info_callback_handler # :nodoc:
          unless @client_info_callback_handler
            @client_info_callback_handler = Proc.new{ |context, client_info, eol, user_data| 
              client = client_info.null? ? nil : Client.new(@operation, client_info)
              callback.call(@operation, client, @operation.user_data) if callback unless eol == 1
            }
          end
        end      

        
        def initialize_client_info_list_callback_handler # :nodoc:
          initialize_list
          unless @client_info_list_callback_handler
            @client_info_list_callback_handler = Proc.new{ |context, client_info, eol, user_data|
              if eol != 1
                @list << Client.new(@operation, client_info)
              else
                callback.call @operation, @list, @operation.user_data if callback
              end
            }
          end
        end      

        def initialize_client_info_list_name_seek_callback_handler # :nodoc:
          initialize_list
          unless @client_info_list_name_seek_callback_handler
            @client_info_list_name_seek_callback_handler = Proc.new{ |context, client_info, eol, user_data|
              if eol != 1
                @list << Client.new(@operation, client_info)
              else
                callback.call @operation, @list.detect{|client| client.name == @name_seek }, @operation.user_data if callback
              end
            }
          end
        end      

        callback :pa_client_info_cb_t, [ :pointer, ::PulseAudio::Asynchronous::Types::Structures::ClientInfo, :int, :pointer ], :void

        attach_function :pa_context_get_client_info_list, [ :pointer, :pa_client_info_cb_t, :pointer ], :pointer
        attach_function :pa_context_get_client_info, [ :pointer, :uint32, :pa_client_info_cb_t, :pointer ], :pointer
    end    
  end
end
