module PulseAudio
  module Asynchronous
    class SourceOutput
      class Operation < ::PulseAudio::Asynchronous::Operation
        extend FFI::Library
        ffi_lib LIB_PA


        protected
          include Common::Callbacks


      end
    end    
  end
end

