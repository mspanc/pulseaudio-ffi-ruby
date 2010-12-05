require 'ffi'

module PulseAudio
  LIB_PA = [ "libpulse.so.0", "libpulse.so", "libpulse" ]
  LIB_PA_GLIB_MAINLOOP = [ "libpulse-mainloop-glib.so.0", "libpulse-mainloop-glib.so", "libpulse-mainloop-glib" ]
  LIB_GLIB = [ "libglib-2.0.so.0", "libglib-2.0.so", "libglib-2.0" ]
  VERSION = "0.0.1"
  
  module MainLoop
    class Base
      def mainloop
        @mainloop
      end
    end
    
    module GLib
      class Loop < ::PulseAudio::MainLoop::Base
        extend FFI::Library
        ffi_lib LIB_PA_GLIB_MAINLOOP
        
        def initialize
          @mainloop = pa_glib_mainloop_new ::PulseAudio::MainLoop::GLib::Context.default
        end
        
        
        def api
          pa_glib_mainloop_get_api @mainloop
        end
        
        protected
          attach_function :pa_glib_mainloop_new, [:pointer], :pointer
          attach_function :pa_glib_mainloop_get_api, [:pointer], :pointer
      
      end
      
      class Context
        extend FFI::Library
        ffi_lib LIB_GLIB
        
        def self.default
          g_main_context_default
        end

        protected
          attach_function :g_main_context_default, [], :pointer
        
      end    
    end  
      
  end
  
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
      raise ArgumentError, "options[:mainloop] must be an object of class derived from PulseAudio::MainLoop::Base but you have passed #{options[:mainloop].class}" unless options[:mainloop].is_a? ::PulseAudio::MainLoop::Base

      options[:name] ||= File.basename($0)

      @context = pa_context_new options[:mainloop].api, options[:name]


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

    def connect(options = {})
      pa_context_connect @context, options[:server], 0, nil            
    end
    
    def state
      pa_context_get_state @context
    end
    
    protected
=begin    
      pa_context* pa_context_new	(	pa_mainloop_api * 	mainloop,
      const char * 	name 
      )		
      Instantiate a new connection context with an abstract mainloop API and an application name.

      It is recommended to use pa_context_new_with_proplist() instead and specify some initial properties.
=end
      attach_function :pa_context_new, [ :pointer, :string ], :pointer
      
=begin    
      int pa_context_connect	(	pa_context * 	c,
      const char * 	server,
      pa_context_flags_t 	flags,
      const pa_spawn_api * 	api 
      )		
      Connect the context to the specified server.

      If server is NULL, connect to the default server. This routine may but will not always return synchronously on error. Use pa_context_set_state_callback() to be notified when the connection is established. If flags doesn't have PA_CONTEXT_NOAUTOSPAWN set and no specific server is specified or accessible a new daemon is spawned. If api is non-NULL, the functions specified in the structure are used when forking a new child process.
=end
      attach_function :pa_context_connect, [ :pointer, :string, :int, :pointer ], :int  # FIXME int as third arg, should be structure

=begin
      void pa_context_set_state_callback	(	pa_context * 	c,
      pa_context_notify_cb_t 	cb,
      void * 	userdata 
      )		
      Set a callback function that is called whenever the context status changes.
=end
      callback :pa_context_notify_cb_t, [ :pointer, :pointer ], :void
      attach_function :pa_context_set_state_callback, [ :pointer, :pa_context_notify_cb_t, :pointer ], :void

=begin      
      pa_context_state_t pa_context_get_state	(	pa_context * 	c )	
      Return the current context status.      
=end
      attach_function :pa_context_get_state, [:pointer], :context_state
      
  end
end

