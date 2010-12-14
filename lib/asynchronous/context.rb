module PulseAudio
  module Asynchronous
    class Context
      extend FFI::Library
      ffi_lib LIB_PA
      
      attr_accessor :state_callback_proc, :state_callback_user_data,
                    :event_callback_proc, :event_callback_user_data

      # Initializes new context (object that represents particular connection to the PulseAudio server).
      # 
      # +options+ is a Hash containing some initial parameters. Valid keys are:
      # * :mainloop (optional) - currently can contain only value of :glib because currently it's only supported mainloop, if not provided, it will be substituted ith :glib,
      # * :name (optional) - application name passed to PulseAudio, if not provided, it will be substituted with result of File.basename($0)
      def initialize(options = {})
        options[:name] ||= File.basename($0)
        options[:mainloop] ||= :glib
        
        @mainloop = case options[:mainloop]
          when :glib
            MainLoop::GLib::Loop.new
          
          else
            raise RuntimeError, "TODO: Currently only implemented MainLoop is GLib, please pass :glib to :mainloop option"
        end

        @context = pa_context_new @mainloop.api, options[:name]
      end

      # Set a callback function that is called whenever a meta/policy control event is received.
      #
      # +proc+ is as Proc object or lambda that accepts four arguments: context, name, proplist, user_data
      #
      # If you want to pass any user data to this callback, use Context#event_callback_user_data=
      def event_callback_proc=(proc)
        unless @event_callback_handler
          @event_callback_handler = Proc.new{|context, name, proplist, user_data| 
            # TODO proplist parsing
            @event_callback_proc.call(self, name, proplist, @event_callback_user_data) if @event_callback_proc
          }
        end
        
        if proc.nil?
          pa_context_set_event_callback @context, nil, nil      
        elsif proc.respond_to? :call
          @event_callback_proc = proc
          pa_context_set_event_callback @context, @event_callback_handler, nil      
        else
          raise ArgumentError, "You mast pass a Proc or lambda to event_callback_proc="
        end
      end

      
      # Set a callback function that is called whenever the context status changes.
      #
      # +proc+ is as Proc object or lambda that accepts two arguments: context, user_data
      #
      # If you want to pass any user data to this callback, use Context#state_callback_user_data=
      def state_callback_proc=(proc)
        unless @state_callback_handler
          @state_callback_handler = Proc.new{|context, user_data| 
            @state_callback_proc.call(self, @state_callback_user_data) if @state_callback_proc
          }
        end
        
        if proc.nil?
          pa_context_set_state_callback @context, nil, nil      
        elsif proc.respond_to? :call
          @state_callback_proc = proc
          pa_context_set_state_callback @context, @state_callback_handler, nil      
        else
          raise ArgumentError, "You mast pass a Proc or lambda to state_callback_proc="
        end
      end
      
      def pointer # :nodoc:
        @context
      end

      # Connect to the server.
      #
      # +options+ is a Hash containing connection parameters. Valid keys are:
      # * :name (optional) - name of the PulseAudio server (useful if there're running more than one),
      def connect(options = {})
        pa_context_connect @context, options[:server], 0, nil     # FIXME hardcoded 0 and nil         
        # TODO proplist support
      end
      
      # Disconnect immediately from the server.
      def disconnect
        pa_context_disconnect @context
      end
      
      # Return current connection state. 
      #
      # Valid states are :unconnected, :connecting, :authorizing, :setting_name, :ready, :failed, :terminated.
      def state
        pa_context_get_state @context
      end
      
      # Return index of client associated with the context.
      def index
        pa_context_get_index @context
      end
      
      # Return protocol version supported by the client.
      def protocol_version
        pa_context_get_protocol_version @context
      end
      
      # Return the server name this context is connected to.
      def server_name
        pa_context_get_server @context
      end
      
      # Return protocol version supported by the server.
      def server_protocol_version
        pa_context_get_server_protocol_version @context
      end
      
      # Return true if connected server is local (on the same machine, not over the network).
      def is_local?
        pa_context_is_local(@context) == 1
      end
      
      # Return true if some data is pending to be written to the connection.
      def is_pending?
        pa_context_is_pending(@context) != 0
      end
      
      # Return a new Context::Operation object.
      #
      # You can use returned object to perform asynchronous tasks on this context.
      #
      # Please read the wiki[https://github.com/saepia/pulseaudio-ffi-ruby/wiki/Documentation-examples] for more information about this syntax.
      def operation(options = nil)
        Operation.new self, options
      end
            

      protected
        include Common::Callbacks
        callback :pa_context_notify_cb_t, [ :pointer, :pointer ], :void
        callback :pa_context_event_cb_t, [ :pointer, :string, :pointer, :pointer ], :void # FIXME pointer as 3rd arg -> Proplist Type

        attach_function :pa_context_new, [ :pointer, :string ], :pointer
        attach_function :pa_context_connect, [ :pointer, :string, :int, :pointer ], :int  # FIXME int as third arg, should be structure
        attach_function :pa_context_disconnect, [ :pointer ], :void
        attach_function :pa_context_set_state_callback, [ :pointer, :pa_context_notify_cb_t, :pointer ], :void
        attach_function :pa_context_set_event_callback, [ :pointer, :pa_context_event_cb_t, :pointer ], :void
        attach_function :pa_context_get_index, [ :pointer ], :uint32
        attach_function :pa_context_get_protocol_version, [ :pointer ], :uint32
        attach_function :pa_context_get_server, [ :pointer ], :string
        attach_function :pa_context_get_server_protocol_version, [ :pointer ], :uint32
        attach_function :pa_context_get_state, [ :pointer ], Types::Enums::ContextState
        attach_function :pa_context_is_local, [ :pointer ], :int
        attach_function :pa_context_is_pending, [ :pointer ], :int
    end
  end
end
