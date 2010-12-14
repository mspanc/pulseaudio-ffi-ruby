module PulseAudio
  module Asynchronous
    class Context
      extend FFI::Library
      ffi_lib LIB_PA
      

      # Initializes new context (object that represents particular connection to the PulseAudio server).
      # 
      # +options+ is a Hash containing some initial parameters. Valid keys are:
      # * :mainloop (optional) - currently can contain only value of :glib because currently it's only supported mainloop, if not provided, it will be substituted ith :glib,
      # * :state_callback_proc (optional, but highly recommended) - has to contain Proc object with two arguments (context, user_data) that will be called on connection's state changes,
      # * :state_callback_user_data (optional) - data that will be passed as second argument to Proc defined as :state_callback_proc's value
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


        # State callback management
        @state_callback_handler = Proc.new{|context, user_data| 
          @state_callback_proc.call(self, @state_callback_user_data) if @state_callback_proc
        }

        if options[:state_callback_proc] and options[:state_callback_proc].is_a? Proc
          @state_callback_proc = options[:state_callback_proc]
          @state_callback_user_data = options[:state_callback_user_data]
        end

        pa_context_set_state_callback @context, @state_callback_handler, nil
      end
      
      def pointer # :nodoc:
        @context
      end

      # Connects to the server.
      #
      # +options+ is a Hash containing connection parameters. Valid keys are:
      # * :name (optional) - name of the PulseAudio server (useful if there're running more than one),
      def connect(options = {})
        pa_context_connect @context, options[:server], 0, nil     # FIXME hardcoded 0 and nil         
        # TODO proplist support
      end
      
      # Disconnects immediately from the server.
      def disconnect
        pa_context_disconnect @context
      end
      
      # Returns current connection state. Valid states are :unconnected, :connecting, :authorizing, :setting_name, :ready, :failed, :terminated.
      def state
        pa_context_get_state @context
      end
      
      # Returns index of client associated with the context.
      def index
        pa_context_get_index @context
      end
      
      # Returns protocol version supported by the client.
      def protocol_version
        pa_context_get_protocol_version @context
      end
      
      def server_name
        pa_context_get_server @context
      end
      
      # Returns protocol version supported by the server.
      def server_protocol_version
        pa_context_get_server_protocol_version @context
      end
      
      # Returns true if connected server is local (on the same machine, not over the network).
      def is_local?
        pa_context_is_local(@context) == 1
      end
      
      def is_pending?
        pa_context_is_pending(@context) != 0
      end
      
      
      def operation(options = nil)
        # FIXME TODO change name to ContextOperation to distinguish from ClientOperation etc.
        Operation.new self, options
      end
            
      # Shortcut for operation.name=
      #
      # Please see Operation#name= for more information.
      def name=(name)
        operation.name = name
      end

      # Shortcut for operation.set_name
      #
      # Please see Operation#set_name for more information.
      def set_name(name)
        operation.set_name name
      end
      
      # Shortcut for operation.exit_daemon!
      #
      # Please see Operation#exit_daemon! for more information.
      def exit_daemon!
        operation.exit_daemon!
      end

      # Shortcut for operation.exit_daemon!
      #
      # Please see Operation#exit_daemon! for more information.
      def exit_daemon!
        operation.exit_daemon!
      end

      protected
        include Common::Callbacks
        callback :pa_context_notify_cb_t, [ :pointer, :pointer ], :void

        attach_function :pa_context_new, [ :pointer, :string ], :pointer
        attach_function :pa_context_connect, [ :pointer, :string, :int, :pointer ], :int  # FIXME int as third arg, should be structure
        attach_function :pa_context_disconnect, [ :pointer ], :void
        attach_function :pa_context_set_state_callback, [ :pointer, :pa_context_notify_cb_t, :pointer ], :void
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
