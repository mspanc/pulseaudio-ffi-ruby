module PulseAudio
  module Asynchronous
    class Operation
      module Errors
        class NotPerformedYetError < Exception
        end
      end
    end
    
    class PropList
      module Errors
        class InvalidKeyError < Exception
        end

        class InvalidValueError < Exception
        end
      end
    end
  end
end   
