module PulseAudio
  module Asynchronous
    # PropList class represents Hash-like object that is internally used by PulseAudio to
    # pass named variables to sinks, modules and other objects.
    #
    # If you do everything correctly, you should not ever had a need to instantiate it directly.
    # It is internally instantiated by Context class with values based upon Hash passed to its constructor.
    #
    # Valid key names are defined in VALID_KEYS constant. Please look to original C library documentation[http://0pointer.de/lennart/projects/pulseaudio/doxygen/proplist_8h.html] for key descriptions.
    class PropList
      extend FFI::Library
      ffi_lib LIB_PA
      
      attr_reader :pointer

      VALID_KEYS =  ["media.name", "media.title", "media.artist", "media.copyright", "media.software", "media.language", "media.filename", "media.role", "event.id", "event.description", "event.mouse.x", "event.mouse.y", "event.mouse.hpos", "event.mouse.vpos", "event.mouse.button", "window.name", "window.id", "window.x", "window.y", "window.width", "window.height", "window.hpos", "window.vpos", "window.desktop", "application.id", "application.version", "application.language", "application.process.id", "application.process.binary", "device.string", "device.api", "device.description", "device.serial", "device.vendor.id", "device.vendor.name", "device.product.id", "device.product.name", "module.author", "module.usage", "module.version"]
      
      VALID_ENUM_VALUES = { "device.access_mode" => [ "mmap", "mmap_rewrite", "serial" ],
                            "device.bus"         => [ "isa", "pci", "usb", "firewire", "bluetooth" ],
                            "device.class"       => [ "sound", "modem", "monitor", "filter" ],
                            "device.form_factor" => [ "internal", "speaker", "handset", "tv", "webcam", "microphone", "headset", "headphone", "hands-free", "car", "hifi", "computer", "portable" ],
                            "media.role"         => [ "video", "music", "game", "event", "phone", "animation", "production", "a11y", "test" ] }
                            
      # Initializes new PropList.
      #
      # +initial_value+ is an optional Hash with initial keys and values.
      def initialize(initial_value = nil)
        @pointer = pa_proplist_new
        
        if initial_value.is_a? Hash
          initial_value.each do |key, value|
            self[key]= value
          end
        end
      end
      
      # Get a string entry from the property list.
      def [](key)
        raise Errors::InvalidKeyError, "Specified key '#{key}' is invalid. Valid keys are #{VALID_KEYS.join(", ")}." unless VALID_KEYS.include? key
        
         pa_proplist_gets @pointer, key     
      end
      
      # Set a string entry on the property list, possibly overwriting an already existing entry with the same key.
      def []=(key, value)
        raise Errors::InvalidKeyError, "Specified key '#{key}' is invalid. Valid keys are #{VALID_KEYS.join(", ")}." unless VALID_KEYS.include? key

        raise Errors::InvalidValueError, "Specified value '#{value}' for key '#{key}' is invalid. Valid values for this key are #{VALID_ENUM_VALUES[key].join(", ")}." unless VALID_ENUM_VALUES[key].include? value if VALID_ENUM_VALUES.has_key? key
        
        pa_proplist_sets @pointer, key, value.to_s
      end
      
      # Removes a single entry from the property list, identified be the specified key name.
      #
      # +key+ is a String with valid key name
      def delete!(key)
        raise Errors::InvalidKeyError, "Specified key '#{key}' is invalid. Valid keys are #{VALID_KEYS.join(", ")}." unless VALID_KEYS.include? key
        
        pa_proplist_unset(@pointer, key) == 0
      end
      
      # Returns true when the proplist is empty (has no keys).
      def empty?
        pa_proplist_isempty(@pointer) == 0
      end
      
      # Return the number of entries on the property list.
      def size
        pa_proplist_size(@pointer)
      end
      
    
      protected
        attach_function :pa_proplist_new, [], :pointer
        attach_function :pa_proplist_sets, [ :pointer, :string, :string ], :int
        attach_function :pa_proplist_gets, [ :pointer, :string ], :string
        attach_function :pa_proplist_gets, [ :pointer, :string ], :string        
        attach_function :pa_proplist_isempty, [ :pointer ], :int	
        attach_function :pa_proplist_unset, [ :pointer, :string ], :int
        attach_function :pa_proplist_size, [ :pointer ], :uint
    end
  end
end
