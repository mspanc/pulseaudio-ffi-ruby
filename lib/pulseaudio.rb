require 'ffi'

module PulseAudio
  LIB_PA = [ "libpulse.so.0", "libpulse.so", "libpulse" ]
  LIB_PA_GLIB_MAINLOOP = [ "libpulse-mainloop-glib.so.0", "libpulse-mainloop-glib.so", "libpulse-mainloop-glib" ]
  LIB_GLIB = [ "libglib-2.0.so.0", "libglib-2.0.so", "libglib-2.0" ]
  VERSION = "0.0.1"
  
  CHANNELS_MAX = 32 # taken from sample.h, has to be 32-bit unsigned integer

  
  module Asynchronous
    module Common # :nodoc:
      module Callbacks # :nodoc:
        def self.included(base) # :nodoc:
          base.class_eval do
            protected 
              callback :pa_context_success_cb_t, [ :pointer, :int, :pointer ], :void
              
              def callback
                @block || @callback_proc # TODO check if @callback_proc still works, when it was @operation.callback_proc, @operation was always nil
              end
              
              def initialize_success_callback_handler # :nodoc:
                unless @success_callback_handler
                  @success_callback_handler = Proc.new{ |context, success, user_data|
                    callback.call self, success == 1, @user_data if callback
                  }
                end
              end

          end
        end
      end
      
      module QueryFunctions # :nodoc:
        def self.included(base) # :nodoc:
          base.class_eval do        
            protected
              def initialize_list
                @list = []
              end

          end
        end
      end
    end
  end
end

load_dir = File.dirname(File.expand_path(__FILE__))

require File.join(load_dir, 'asynchronous/errors')
require File.join(load_dir, 'asynchronous/types/typedefs')
require File.join(load_dir, 'asynchronous/types/enums')
require File.join(load_dir, 'asynchronous/types/structures')
require File.join(load_dir, 'asynchronous/mainloop/glib')
require File.join(load_dir, 'asynchronous/operation')

require File.join(load_dir, 'asynchronous/proplist')

require File.join(load_dir, 'asynchronous/context')
require File.join(load_dir, 'asynchronous/operation/context')

require File.join(load_dir, 'asynchronous/client')
require File.join(load_dir, 'asynchronous/operation/client')

require File.join(load_dir, 'asynchronous/sink')
require File.join(load_dir, 'asynchronous/operation/sink')

require File.join(load_dir, 'asynchronous/sink-input')
require File.join(load_dir, 'asynchronous/operation/sink-input')

require File.join(load_dir, 'asynchronous/module')
require File.join(load_dir, 'asynchronous/operation/module')

