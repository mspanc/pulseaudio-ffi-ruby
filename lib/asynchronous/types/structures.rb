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
      end
    end
  end
end    
