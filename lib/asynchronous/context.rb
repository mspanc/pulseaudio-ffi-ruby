module PulseAudio
  module Asynchronous
    class Context < DaemonObject
      extend FFI::Library
      ffi_lib LIB_PA
      
      attr_accessor :state_callback_proc, :state_callback_user_data,
                    :event_callback_proc, :event_callback_user_data,
                    :subscribe_callback_proc, :subscribe_callback_user_data
                    
      attr_reader   :properties

      # Initializes new context (object that represents particular connection to the PulseAudio server).
      # 
      # +options+ is an optional Hash containing some initial parameters. Valid keys are:
      # * :mainloop (optional) - currently can contain only value of :glib because currently it's only supported mainloop, if not provided, it will be substituted ith :glib,
      # * :name (optional) - application name passed to PulseAudio, if not provided, it will be substituted with result of File.basename($0)
      # * :properties (optional) - Hash containing some context descriptive properties. Please see PropList for more information about valid keys and values and original C library documentation[http://0pointer.de/lennart/projects/pulseaudio/doxygen/proplist_8h.html] for key descriptions.
      def initialize(options = {}, properties = {})
        options[:name] ||= File.basename($0)
        options[:mainloop] ||= :glib
        
        @mainloop = case options[:mainloop]
          when :glib
            MainLoop::GLib::Loop.new
          
          else
            raise RuntimeError, "TODO: Currently only implemented MainLoop is GLib, please pass :glib to :mainloop option"
        end

        if options[:properties]
          @properties = PropList.new options[:properties]
          @context = pa_context_new_with_proplist @mainloop.api, options[:name], @properties.pointer
        else
          @context = pa_context_new @mainloop.api, options[:name]
        end
      end

      # Set the context specific call back function that is called whenever the state of the daemon changes.
      #
      # +proc+ is as Proc object or lambda that accepts four arguments: context, facility, event_type, index, user_data
      #
      # Parameters passed to +proc+ are:
      #
      # +context+ - context used to read the subscribtion message
      #
      # +facility+ - one of :sink, :source, :sink_input, :source_output, :module, :client, :sample_cache, :server, :autoload, :card
      #
      # +event_type+ - one of :new, :change, :remove
      #
      # +index+ - PulseAudio object's index that causes subscribtion
      #
      # +user_data+ - user data passed to subscribe_callback_user_data= of the active context
      #
      # If you want to pass any user data to this callback, use Context#event_callback_user_data=
      def subscribe_callback_proc=(proc)
        unless @subscribe_callback_handler
          @subscribe_callback_handler = Proc.new{|context, event_type, index, user_data| 
            # Needs workaround and manual resolution, because PA API specifies
            # the same values 0x0000 etc. for multiple identifiers in 
            # Types::Enums::SubscriptionEventType so FFI resolution mechanism 
            # is always getting the last value.
            #
            # Of course this should be Enum in normal case.

            facilities = { 0x0000 => :sink,
                           0x0001 => :source,
                           0x0002 => :sink_input,
                           0x0003 => :source_output,
                           0x0004 => :module,
                           0x0005 => :client,
                           0x0006 => :sample_cache,
                           0x0007 => :server,
                           0x0008 => :autoload,
                           0x0009 => :card }
                           
            types = { 0x0000 => :new,
                      0x0010 => :change,
                      0x0020 => :remove }
                            
            facility_mask = 0x000F
            type_mask = 0x0030
                                           
            facility = facilities[event_type & facility_mask]
            type = types[event_type & type_mask]

            @subscribe_callback_proc.call(self, facility, type, index, @subscribe_callback_user_data) if @subscribe_callback_proc
          }
        end
        
        if proc.nil?
          pa_context_set_subscribe_callback @context, nil, nil      
        elsif proc.respond_to? :call
          @subscribe_callback_proc = proc
          pa_context_set_subscribe_callback @context, @subscribe_callback_handler, nil
        else
          raise ArgumentError, "You mast pass a Proc or lambda to subscribe_callback_proc="
        end
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
        callback :pa_context_subscribe_cb_t, [ :pointer, :uint32, :uint32, :pointer ], :void # Required to use uint32 instead of Types::Enums::SubscriptionEventType
                                                                                             # because passed value can be bigger than enum range. Exact event type
                                                                                             # etc. is extracted using binary AND - please look in the callback code.

        attach_function :pa_context_new, [ :pointer, :string ], :pointer
        attach_function :pa_context_new_with_proplist, [ :pointer, :string, :pointer ], :pointer
        attach_function :pa_context_connect, [ :pointer, :string, :int, :pointer ], :int  # FIXME int as third arg, should be structure
        attach_function :pa_context_disconnect, [ :pointer ], :void
        attach_function :pa_context_set_state_callback, [ :pointer, :pa_context_notify_cb_t, :pointer ], :void
        attach_function :pa_context_set_event_callback, [ :pointer, :pa_context_event_cb_t, :pointer ], :void
        attach_function :pa_context_set_subscribe_callback, [ :pointer, :pa_context_subscribe_cb_t, :pointer ], :void
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
