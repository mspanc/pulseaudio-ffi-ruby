module PulseAudio
  module Asynchronous
    class Client
      attr_reader :index, :name, :owner_module, :driver, :proplist, :operation
      
      def initialize(operation, constructor)
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
      
      def me?
        @operation.context.index == @index
      end
    end  
    
    
    
    class Clients      
      extend FFI::Library
      ffi_lib LIB_PA
      
      attr_reader :operation
      
      def initialize(operation)
        @operation = operation
      end
            
      def all
        initialize_client_info_list_callback_handler
        pa_context_get_client_info_list @operation.context.pointer, @client_info_list_callback_handler, nil
      end
      
      def [](x)
        case x
          when Fixnum
            initialize_client_info_callback_handler
            pa_context_get_client_info @operation.context.pointer, x, @client_info_callback_handler, nil
          
          when String
            initialize_client_info_list_name_seek_callback_handler
            @name_seek = x
            pa_context_get_client_info_list @operation.context.pointer, @client_info_list_name_seek_callback_handler, nil
            
          else
            raise ArgumentError, "Argument passed to PulseAudio::Asynchronous::Clients::[] has to be Fixnum or String"
        end
      end

      protected
        def initialize_list
          @list = []
        end

        def initialize_client_info_callback_handler
          unless @client_info_callback_handler
            @client_info_callback_handler = Proc.new{ |context, client_info, eol, user_data| 
              client = client_info.null? ? nil : ::PulseAudio::Asynchronous::Client.new(@operation, client_info)
              @operation.callback_proc.call(@operation, client, @operation.user_data) if @operation.callback_proc unless eol == 1
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
                @operation.callback_proc.call @operation, @list, @operation.user_data if @operation.callback_proc 
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
                @operation.callback_proc.call @operation, @list.detect{|client| client.name == @name_seek }, @operation.user_data if @operation.callback_proc 
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
