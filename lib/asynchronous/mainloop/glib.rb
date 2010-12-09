module PulseAudio
  module Asynchronous
    module MainLoop
      module GLib
        class Loop
          extend FFI::Library
          ffi_lib LIB_PA_GLIB_MAINLOOP

          attr_reader :mainloop
          
          def initialize
            @mainloop = pa_glib_mainloop_new ::PulseAudio::Asynchronous::MainLoop::GLib::Context.default
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
  end
end
