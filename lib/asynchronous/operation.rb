module PulseAudio
  module Asynchronous
    class Operation
      extend FFI::Library
      ffi_lib LIB_PA



      attr_reader :context, :pointer, :callback_proc, :user_data

      def initialize(context, options = {})
        @context = context

        if options
          @user_data = options[:user_data]
          @callback_proc = options[:callback_proc]
        end

        @pointer = nil
      end

      def state
        raise ::PulseAudio::Asynchronous::Errors::OperationNotPerformedYetError, "You must perform some action first on this PulseAudio::Operation object to check its state" unless @pointer
        
        pa_operation_get_state @pointer
      end
      
      def cancel!
        pa_operation_cancel @pointer
        nil
      end



      def name=(name)
        initialize_success_callback_handler
        @pointer = pa_context_set_name @context.pointer, name, @success_callback_handler, nil
      end
      
      def exit_daemon!
        initialize_success_callback_handler
        @pointer = pa_context_exit_daemon @context.pointer, @success_callback_handler, nil
      end
      
      def server_info
        initialize_server_info_callback_handler
        pa_context_get_server_info @context.pointer, @server_info_callback_handler, nil
      end
      
      def clients
        Clients.new self
      end
      
      # TODO Move to operation.sinks.default etc.
      def default_sink
        # TODO
      end

      def default_sink=(sink)
        # TODO
      end

      def default_source
        # TODO
      end

      def default_source=(source)
        # TODO
      end
      
      
      

      protected

      
        def initialize_server_info_callback_handler
          unless @server_info_callback_handler
            @server_info_callback_handler = Proc.new{ |context, server_info, user_data|
              struct = Types::Structures::ServerInfo.new server_info
              
              info = { :user_name => struct[:user_name],
                       :host_name => struct[:host_name],            
                       :server_version => struct[:server_version],            
                       :server_name => struct[:server_name],            
                       :default_sink_name => struct[:default_sink_name],
                       :default_source_name => struct[:default_source_name],
                       :cookie => struct[:cookie],
                       :sample_spec => { :format   => struct[:sample_spec][:format],
                                         :rate     => struct[:sample_spec][:rate],
                                         :channels => struct[:sample_spec][:channels] },
                       :channel_map => { :channels => struct[:channel_map][:channels],
                                         :map => struct[:channel_map][:map].to_a } # TODO FIXME use enums instead of numbers, currently unsupported in FFI
                     }
              

              @callback_proc.call self, info, @user_data if @callback_proc
            }
          end
        end
        
        def initialize_success_callback_handler
          unless @success_callback_handler
            @success_callback_handler = Proc.new{ |context, success, user_data|
              @callback_proc.call self, success == 1, @user_data if @callback_proc
            }
          end
        end
    
        
        include Common::Callbacks
        callback :pa_server_info_cb_t, [ :pointer, Types::Structures::ServerInfo, :pointer ], :void
        
        attach_function :pa_context_set_name, [ :pointer, :string, :pa_context_success_cb_t, :pointer ], :pointer
        attach_function :pa_operation_get_state, [ :pointer ], Types::Enums::OperationState
        attach_function :pa_operation_cancel, [ :pointer ], :void
        attach_function :pa_context_exit_daemon, [ :pointer, :pa_context_success_cb_t, :pointer ], :pointer
        attach_function :pa_context_get_server_info, [ :pointer, :pa_server_info_cb_t, :pointer ], :pointer


    end
    

  end
end

