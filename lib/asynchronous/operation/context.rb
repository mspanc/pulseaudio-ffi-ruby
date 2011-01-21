module PulseAudio
  module Asynchronous
    class Context
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA

        # Sets a new name +name+ for client associated with this context in the PulseAudio server.
        #
        # TODO FIXME missing block!
        def name=(name)
          initialize_success_callback_handler
          @pointer = pa_context_set_name @parent.pointer, name, @success_callback_handler, nil
        end
        alias_method :set_name, :name=

        # Tell the daemon to exit.
        #
        # The returned operation is unlikely to complete succesfully, since the daemon probably
        # died before returning a success notification.
        #
        # TODO FIXME missing block!
        def exit_daemon!
          initialize_success_callback_handler
          @pointer = pa_context_exit_daemon @parent.pointer, @success_callback_handler, nil
        end
        
        # TODO FIXME missing block!
        def server_info
          initialize_server_info_callback_handler
          pa_context_get_server_info @parent.pointer, @server_info_callback_handler, nil
        end
        
        # Returns PulseAudio::Asynchronous::Clients object, which can be used to query information
        # about clients connected to the server.
        def clients
          Clients.new self
        end
        
        # Returns PulseAudio::Asynchronous::Sinks object, which can be used to query information
        # about available sinks.
        def sinks
          Sinks.new self
        end
        
        # Returns PulseAudio::Asynchronous::SinkInputs object, which can be used to query information
        # about available sink inputs.
        def sink_inputs
          SinkInputs.new self
        end

        # Returns PulseAudio::Asynchronous::Modules object, which can be used to query information
        # about available sink inputs.
        def modules
          Modules.new self
        end        
        
        # Enable event notification.
        #
        # +subscription_mask+ must be one of :null, :sink, :source, :sink_input, :source_output, :module, :client, :sample_cache, :server, :card, :all (default is :all)
        def subscribe!(subscription_mask = :all, &b) # :yields: operation, success, user_data
          raise ArgumentError, "subscription_mask must be one of :null, :sink, :source, :sink_input, :source_output, :module, :client, :sample_cache, :server, :card, :all" unless [ :null, :sink, :source, :sink_input, :source_output, :module, :client, :sample_cache, :server, :card, :all ].include? subscription_mask

          initialize_success_callback_handler              
          @block = b

          # FIXME why FFI needs explicit conversion like Types::Enums::SubscriptionMask[subscription_mask]? Shouldn't it automatically recognize that this parameters is enum and convert symbol to integer?
          pa_context_subscribe @parent.pointer, Types::Enums::SubscriptionMask[subscription_mask], @success_callback_handler, nil
        end

        protected
          include Common::Callbacks

          callback :pa_server_info_cb_t, [ :pointer, Types::Structures::ServerInfo, :pointer ], :void

          attach_function :pa_context_set_name, [ :pointer, :string, :pa_context_success_cb_t, :pointer ], :pointer
          attach_function :pa_context_exit_daemon, [ :pointer, :pa_context_success_cb_t, :pointer ], :pointer
          attach_function :pa_context_get_server_info, [ :pointer, :pa_server_info_cb_t, :pointer ], :pointer
          attach_function :pa_context_subscribe, [ :pointer, Types::Enums::SubscriptionMask, :pa_context_success_cb_t, :pointer ], :pointer
        
          def initialize_server_info_callback_handler # :nodoc:
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
                

                callback.call self, info, @user_data if callback
              }
            end
          end
          

          


      end
    end    
  end
end

