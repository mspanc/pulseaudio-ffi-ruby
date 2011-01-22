module PulseAudio
  module Asynchronous
    class Source
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA

        protected
          include Common::Callbacks
          

      end
    end    
  end
end

