module PulseAudio
  module Asynchronous
    module Types
      module Structures
        class ClientInfo < ::FFI::Struct
          layout :index, :uint32, 
                 :name, :string,
                 :owner_module, :uint32,
                 :driver, :string,
                 :proplist, :pointer  # FIXME pointer => change to pa_proplist
                 
        end
        
        class SampleSpec < ::FFI::Struct
          layout :format, Enums::Format,
                 :rate, :uint32,
                 :channels, :uint8
        end
        
        class ChannelMap < ::FFI::Struct
          layout :channels, :uint8,
                 :map, [ :int, ::PulseAudio::CHANNELS_MAX ]
    #             :map, [ :channel_position, PulseAudio::CHANNELS_MAX ] FIXME TODO use enums instead of numbers, FFI currently does not support that
        end


        class ServerInfo < ::FFI::Struct
          layout :user_name, :string,
                 :host_name, :string,
                 :server_version, :string,
                 :server_name, :string,
                 :sample_spec, SampleSpec, 
                 :default_sink_name, :string,
                 :default_source_name, :string,
                 :cookie, :uint32,
                 :channel_map, ChannelMap
        end        
      end
    end
  end
end    
