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
        
        class CVolume < ::FFI::Struct
          layout :channels, :uint8,
                 :values, [ Typedefs::Volume_t, ::PulseAudio::CHANNELS_MAX ]
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
        
        class SinkPortInfo < ::FFI::Struct
          layout :name, :string,
                 :description, :string,
                 :priority, :uint32
        end

        class SourcePortInfo < ::FFI::Struct
          layout :name, :string,
                 :description, :string,
                 :priority, :uint32
        end
        
        class SinkInputInfo < ::FFI::Struct
          layout :index, :uint32,
                 :name, :string,
                 :owner_module, :uint32,
                 :client, :uint32,
                 :sink, :uint32, 
                 :sample_spec, SampleSpec,
                 :channel_map, ChannelMap,
                 :volume, CVolume,
                 :buffer_usec, Typedefs::Usec_t,
                 :sink_usec, Typedefs::Usec_t,
                 :resample_method, :string,
                 :driver, :string,
                 :mute, :int,
                 :proplist, :pointer # FIXME to proplist
        end
        
        class SourceOutputInfo < ::FFI::Struct
          layout :index, :uint32,
                 :name, :string,
                 :owner_module, :uint32,
                 :client, :uint32,
                 :source, :uint32, 
                 :sample_spec, SampleSpec,
                 :channel_map, ChannelMap,
                 :buffer_usec, Typedefs::Usec_t,
                 :source_usec, Typedefs::Usec_t,
                 :resample_method, :string,
                 :driver, :string,
                 :proplist, :pointer # FIXME to proplist
        end        
                
        class SinkInfo < ::FFI::Struct
          layout :name, :string,
                 :index, :uint32,
                 :description, :string,
                 :sample_spec, SampleSpec,
                 :channel_map, ChannelMap,
                 :owner_module, :uint32,
                 :volume, CVolume,
                 :mute, :int,
                 :monitor_source, :uint32,
                 :monitor_source_name, :string,
                 :latency, Typedefs::Usec_t,
                 :driver, :string,
                 :flags, :uint32,  # uint32 instead of Enums::SinkFlags -> please see Common::FlagsFunctions::parse_flags
                 :proplist, :pointer, # FIXME pa_proplist
                 :configured_latency, Typedefs::Usec_t,
                 :base_volume, Typedefs::Volume_t,
                 :state, Enums::SinkState,
                 :n_volume_steps, :uint32,
                 :card, :uint32,
                 :n_ports, :uint32,
                 :ports, :pointer, # FIXME array of SinkPortInfo
                 :active_port, SinkPortInfo
                 
        end
        
        class SourceInfo < ::FFI::Struct
          layout :name, :string,
                 :index, :uint32,
                 :description, :string,
                 :sample_spec, SampleSpec,
                 :channel_map, ChannelMap,
                 :owner_module, :uint32,
                 :volume, CVolume,
                 :mute, :int,
                 :monitor_of_sink, :uint32,
                 :monitor_of_sink_name, :string,
                 :latency, Typedefs::Usec_t,
                 :driver, :string,
                 :flags, :uint32,  # uint32 instead of Enums::SourceFlags -> please see Common::FlagsFunctions::parse_flags
                 :proplist, :pointer, # FIXME pa_proplist
                 :configured_latency, Typedefs::Usec_t,
                 :base_volume, Typedefs::Volume_t,
                 :state, Enums::SourceState,
                 :n_volume_steps, :uint32,
                 :card, :uint32,
                 :n_ports, :uint32,
                 :ports, :pointer, # FIXME array of SinkPortInfo
                 :active_port, SourcePortInfo
                 
        end        
                
        class ModuleInfo < ::FFI::Struct
          layout :index, :uint32,
                 :name, :string,
                 :argument, :string,
                 :n_used, :uint32,
                 :proplist, :pointer # FIXME to proplisdt
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
