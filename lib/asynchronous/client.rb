module PulseAudio
  module Asynchronous
    class Client
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :index, :name, :owner_module, :driver, :proplist, :operation
      
      def initialize(operation, constructor) # :nodoc:
        @operation = operation
        
        if constructor.is_a? FFI::Pointer
          struct = Types::Structures::ClientInfo.new constructor
          @index = struct[:index]
          @name = struct[:name]
#          @owner_module = struct[:name] # TODO - map to Module class
          @driver = struct[:driver]
#          @proplist = # TODO map to proplist structure          
        end
      end
      
      # Checks if this particular object represents the same client that was used to query one.
      # In other words, it says if this object is your application.
      def me?
        @operation.context.index == @index
      end
      
      # Kills this client or disconnects the context if it is invoked on myself.
      def kill!
        # FIXME TODO add .operation syntax for asynchronous operation like killing clients

        if me?
          @operation.context.disconnect
        else
#          pa_context_kill_client @operation.context.pointer, @index, @kill_client_callback_handler, nil
        end
      end
      
      protected
        include Common::Callbacks
        attach_function :pa_context_kill_client, [ :pointer, :uint32, :pa_context_success_cb_t, :pointer ], :pointer
    end  
    
    
    
    class Clients      
      extend FFI::Library
      ffi_lib LIB_PA

      include Common::QueryFunctions

      
      attr_reader :operation
      
      def initialize(operation) # :nodoc:
        @operation = operation
      end
      
      # Get list of all clients connected to the PulseAudio server
      def all(&b)
        @block = b
        
        initialize_client_info_list_callback_handler
        pa_context_get_client_info_list @operation.context.pointer, @client_info_list_callback_handler, nil
      end

      # Get particular client connected to the PulseAudio server identified by its index or name.
      def find(seek, &b)
        @block = b

        case seek
          when Fixnum
            initialize_client_info_callback_handler
            pa_context_get_client_info @operation.context.pointer, seek, @client_info_callback_handler, nil
          
          when String
            initialize_client_info_list_name_seek_callback_handler
            @name_seek = seek
            pa_context_get_client_info_list @operation.context.pointer, @client_info_list_name_seek_callback_handler, nil
            
          else
            raise ArgumentError, "Argument passed to PulseAudio::Asynchronous::Clients::[] has to be Fixnum or String"
        end
      end

      protected
        def initialize_client_info_callback_handler
          unless @client_info_callback_handler
            @client_info_callback_handler = Proc.new{ |context, client_info, eol, user_data| 
              client = client_info.null? ? nil : ::PulseAudio::Asynchronous::Client.new(@operation, client_info)
              callback.call(@operation, client, @operation.user_data) if callback unless eol == 1
            }
          end
        end      

        
        def initialize_client_info_list_callback_handler
          initialize_list
          unless @client_info_list_callback_handler
            @client_info_list_callback_handler = Proc.new{ |context, client_info, eol, user_data|
              if eol != 1
                @list << ::PulseAudio::Asynchronous::Client.new(@operation, client_info)
              else
                callback.call @operation, @list, @operation.user_data if callback
              end
            }
          end
        end      

        def initialize_client_info_list_name_seek_callback_handler
          initialize_list
          unless @client_info_list_name_seek_callback_handler
            @client_info_list_name_seek_callback_handler = Proc.new{ |context, client_info, eol, user_data|
              if eol != 1
                @list << ::PulseAudio::Asynchronous::Client.new(@operation, client_info)
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
