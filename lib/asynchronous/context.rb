module PulseAudio
  module Asynchronous
    class Context
      extend FFI::Library
      ffi_lib LIB_PA
      
      enum :context_state, [ :unconnected,
                             :connecting,
                             :authorizing,
                             :setting_name,
                             :ready,
                             :failed,
                             :terminated ]

      def initialize(options = {})
      
# TODO     
#        raise ArgumentError, "options[:mainloop] must be an object of class derived from PulseAudio::MainLoop::Base but you have passed #{options[:mainloop].class}" unless options[:mainloop].is_a? ::PulseAudio::Asynchronous::MainLoop::Base

        options[:name] ||= File.basename($0)
        
        @mainloop = case options[:mainloop]
          when :glib
            PulseAudio::Asynchronous::MainLoop::GLib::Loop.new
          
          else
            raise RuntimeError, "TODO: Currently only implemented MainLoop is GLib"
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
      
      def pointer
        @context
      end

      def connect(options = {})
        pa_context_connect @context, options[:server], 0, nil     # FIXME hardcoded 0 and nil         
        # TODO proplist support
      end
      
      def disconnect
        pa_context_disconnect @context
      end
      
      def state
        pa_context_get_state @context
      end
      
      def index
        pa_context_get_index @context
      end
      
      def protocol_version
        pa_context_get_protocol_version @context
      end
      
      def server_name
        pa_context_get_server @context
      end
      
      def operation(options = nil)
        ::PulseAudio::Asynchronous::Operation.new self, options
      end
      
      
      def server_protocol_version
        pa_context_get_server_protocol_version @context
      end
      
      def is_local?
        pa_context_is_local(@context) == 1
      end
      
      def is_pending?
        pa_context_is_pending(@context) != 0
      end
      
      
      protected
        # FIXME DRY - move callbacks to module
        callback :pa_context_success_cb_t, [ :pointer, :int, :pointer ], :void
        callback :pa_context_notify_cb_t, [ :pointer, :pointer ], :void

        attach_function :pa_context_new, [ :pointer, :string ], :pointer
        attach_function :pa_context_connect, [ :pointer, :string, :int, :pointer ], :int  # FIXME int as third arg, should be structure
        attach_function :pa_context_disconnect, [ :pointer ], :void
        attach_function :pa_context_set_state_callback, [ :pointer, :pa_context_notify_cb_t, :pointer ], :void
        attach_function :pa_context_get_index, [ :pointer ], :uint32
        attach_function :pa_context_get_protocol_version, [ :pointer ], :uint32
        attach_function :pa_context_get_server, [ :pointer ], :string
        attach_function :pa_context_get_server_protocol_version, [ :pointer ], :uint32
        attach_function :pa_context_get_state, [ :pointer ], :context_state
        attach_function :pa_context_is_local, [ :pointer ], :int
        attach_function :pa_context_is_pending, [ :pointer ], :int
    end
  end
end
