module PulseAudio
  module Asynchronous
    module Types
      class Typedefs
        extend FFI::Library

        Volume_t = typedef :uint32, :pa_volume_t
        Usec_t = typedef :uint64, :pa_usec_t
        
      end
    end
  end
end    
