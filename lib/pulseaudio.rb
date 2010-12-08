require 'ffi'

module PulseAudio
  LIB_PA = [ "libpulse.so.0", "libpulse.so", "libpulse" ]
  LIB_PA_GLIB_MAINLOOP = [ "libpulse-mainloop-glib.so.0", "libpulse-mainloop-glib.so", "libpulse-mainloop-glib" ]
  LIB_GLIB = [ "libglib-2.0.so.0", "libglib-2.0.so", "libglib-2.0" ]
  VERSION = "0.0.1"
  
  CHANNELS_MAX = 32 # taken from sample.h, has to be 32-bit unsigned integer
  
  class Simple
    # TODO
    # DRY sample spec etc.
  end
  
  module Asynchronous
    module MainLoop
      class Base
        def mainloop
          @mainloop
        end
      end
      
      module GLib
        class Loop < ::PulseAudio::Asynchronous::MainLoop::Base
          extend FFI::Library
          ffi_lib LIB_PA_GLIB_MAINLOOP
          
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
    
    module Errors
      class OperationNotPerformedYetError < Exception
      end
    end
    
    class Operation
      extend FFI::Library
      ffi_lib LIB_PA

      enum :format, [ :u8,
                      :alaw,
                      :ulaw,
                      :s16le,
                      :s16be,
                      :float32le,
                      :float32be,
                      :s32le,
                      :s32be,
                      :s24le,
                      :s24be,
                      :s24_32le,
                      :s24_32be,
                      :max,
                      :invalid ]
                      
      enum :channel_position, [
                      :position_invalid,
                      :position_mono,
                      :position_front_left,
                      :position_front_right,
                      :position_front_center,
                      :position_rear_center,
                      :position_rear_left,
                      :position_rear_right,
                      :position_lfe,
                      :position_front_left_of_center,
                      :position_front_right_of_center,
                      :position_side_left,
                      :position_side_right,
                      :position_aux0,
                      :position_aux1,
                      :position_aux2,
                      :position_aux3,
                      :position_aux4,
                      :position_aux5,
                      :position_aux6,
                      :position_aux7,
                      :position_aux8,
                      :position_aux9,
                      :position_aux10,
                      :position_aux11,
                      :position_aux12,
                      :position_aux13,
                      :position_aux14,
                      :position_aux15,
                      :position_aux16,
                      :position_aux17,
                      :position_aux18,
                      :position_aux19,
                      :position_aux20,
                      :position_aux21,
                      :position_aux22,
                      :position_aux23,
                      :position_aux24,
                      :position_aux25,
                      :position_aux26,
                      :position_aux27,
                      :position_aux28,
                      :position_aux29,
                      :position_aux30,
                      :position_aux31,
                      :position_top_center,
                      :position_top_front_left,
                      :position_top_front_right,
                      :position_top_front_center,
                      :position_top_rear_left,
                      :position_top_rear_right,
                      :position_top_rear_center,
                      :position_max ]    

      class SampleSpecStruct < ::FFI::Struct
        layout :format, :format,
               :rate, :uint32,
               :channels, :uint8
      end
      
      class ChannelMapStruct < ::FFI::Struct
        layout :channels, :uint8,
               :map, [ :uint32, ::PulseAudio::CHANNELS_MAX ]
  #             :map, [ :channel_position, PulseAudio::CHANNELS_MAX ] FIXME TODO use enums instead of numbers
      end

      class ServerInfoStruct < ::FFI::Struct
        layout :user_name, :string,
               :host_name, :string,
               :server_version, :string,
               :server_name, :string,
               :sample_spec, SampleSpecStruct, 
               :default_sink_name, :string,
               :default_source_name, :string,
               :cookie, :uint32,
               :channel_map, ChannelMapStruct
      end


      enum :operation_state, [ :running,
                               :done,
                               :cancelled ]

      attr_reader :callback, :context, :pointer

      def initialize(context, options = {})
        @context = context
        @user_data = options[:user_data]
        @callback_proc = options[:callback_proc]
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
              struct = ServerInfoStruct.new server_info
              
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
    
        
        callback :pa_context_success_cb_t, [ :pointer, :int, :pointer ], :void
  #      callback :pa_stat_info_cb_t, [ :pointer, StatInfoStruct, :pointer ], :void # FIXME
        callback :pa_server_info_cb_t, [ :pointer, ServerInfoStruct, :pointer ], :void
        
        attach_function :pa_context_set_name, [ :pointer, :string, :pa_context_success_cb_t, :pointer ], :pointer
        attach_function :pa_operation_get_state, [ :pointer ], :operation_state
        attach_function :pa_operation_cancel, [ :pointer ], :void
        attach_function :pa_context_exit_daemon, [ :pointer, :pa_context_success_cb_t, :pointer ], :pointer
  #      attach_function :pa_context_stat, [ :pointer, :pa_stat_info_cb_t, :pointer ], :pointer # FIXME
        attach_function :pa_context_get_server_info, [ :pointer, :pa_server_info_cb_t, :pointer ], :pointer

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

