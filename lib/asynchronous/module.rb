module PulseAudio
  module Asynchronous
    class Module < DaemonObject
      extend FFI::Library
      ffi_lib LIB_PA

      attr_reader :operation, :context

      attr_reader :index, :name, :argument, :n_used, :proplist
      
      def initialize(operation, constructor) # :nodoc:
        @operation = operation
        @context = operation.parent

        struct = Types::Structures::ModuleInfo.new constructor
        @index = struct[:index]
        @name = struct[:name]
        @n_used = struct[:n_used]
        
        @proplist = PropList.new struct[:proplist]

      end
      
      # Return a new Module::Operation object.
      #
      # You can use returned object to perform asynchronous tasks on this sink.
      #
      # Please read the wiki[https://github.com/saepia/pulseaudio-ffi-ruby/wiki/Documentation-examples] for more information about this syntax.
      def operation(options = nil)
        Operation.new self, options
      end      
      
      
      def inspect # :nodoc:
        "#<#{self.class} ##{index} \"#{name}\">"
      end
    end  
    
    
    
    class Modules      
      extend FFI::Library
      ffi_lib LIB_PA

      include Common::Callbacks
      include Common::QueryFunctions

      
      attr_reader :operation
      
      def initialize(operation) # :nodoc:
        @operation = operation
      end
      
      # Get list of all loaded modules.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +list+ is an array of PulseAudio::Asynchronous::Module objects found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def all(&b) # :yields: operation, list, user_data
        @block = b
        
        initialize_module_info_list_callback_handler
        pa_context_get_module_info_list @operation.parent.pointer, @module_info_list_callback_handler, nil
      end

      # Get particular Module loaded to the PulseAudio server identified by its index or name.
      #
      # +seek+ is a Fixnum (if you seek by module's index) or String (if you seek by module's name).
      #
      # Seeking via name internally calls function similar to all, so please note that it can be less 
      # efficient than seeking by ID.
      #
      # Block passed to the function will be called when asynchronous query operation finishes.
      # Parameters passed to the block are:
      #
      # +operation+ is an Operation object used to perform the query.
      #
      # +mod+ is PulseAudio::Asynchronous::Module found with the query.
      #
      # +user_data+ is an object passed to Operation object constructor or nil.
      def find(seek, &b) # :yields: operation, mod, user_data
        @block = b

        case seek
          when Fixnum
            initialize_module_info_callback_handler
            pa_context_get_module_info @operation.parent.pointer, seek, @module_info_callback_handler, nil
          
          when String
            initialize_module_info_list_name_seek_callback_handler
            @name_seek = seek
            pa_context_get_module_info_list @operation.parent.pointer, @module_info_list_name_seek_callback_handler, nil
            
          else
            raise ArgumentError, "Argument passed to PulseAudio::Asynchronous::Modules::find has to be Fixnum or String"
        end
      end
      
      # Load a module.
      #
      # +name+ is a String containing name of one of available modules
      #
      # +argument+ is a String with arguments passed to the module      
      #
      # Please see official PulseAudio documentation[http://pulseaudio.org/wiki/Modules] for more information.
      def load(name, argument = "", &b) # :yields: operation, index, user_data
        @block = b
        initialize_load_module_callback_handler
        
        pa_context_load_module @operation.parent.pointer, name, argument, @load_module_callback_handler, nil
      end


      protected
        callback :pa_module_info_cb_t, [ :pointer, ::PulseAudio::Asynchronous::Types::Structures::ModuleInfo, :int, :pointer ], :void
        callback :pa_context_index_cb_t, [ :pointer, :uint32, :pointer ], :void
        
        attach_function :pa_context_get_module_info, [ :pointer, :uint32, :pa_module_info_cb_t, :pointer ], :pointer
        attach_function :pa_context_get_module_info_list, [ :pointer, :pa_module_info_cb_t, :pointer ], :pointer
        attach_function :pa_context_load_module, [ :pointer, :string, :string, :pa_context_index_cb_t, :pointer ], :pointer

        def initialize_load_module_callback_handler # :nodoc:
          unless @load_module_callback_handler
            @load_module_callback_handler = Proc.new{ |context, index, user_data|
              callback.call @operation, index, @operation.user_data if callback
            } 
          end
        end
        
        def initialize_module_info_list_callback_handler # :nodoc:
          initialize_list
          unless @module_info_list_callback_handler
            @module_info_list_callback_handler = Proc.new{ |context, module_info, eol, user_data|
              if eol != 1
                @list << Module.new(@operation, module_info)
              else
                callback.call @operation, @list, @operation.user_data if callback
              end
            }
          end
        end        
        

        def initialize_module_info_callback_handler # :nodoc:
          unless @module_info_callback_handler
            @module_info_callback_handler = Proc.new{ |context, module_info, eol, user_data| 
              mod = module_info.null? ? nil : Module.new(@operation, module_info)
              callback.call(@operation, mod, @operation.user_data) if callback unless eol == 1
            }
          end
        end      

        
        def initialize_module_info_list_name_seek_callback_handler # :nodoc:
          initialize_list
          unless @module_info_list_name_seek_callback_handler
            @module_info_list_name_seek_callback_handler = Proc.new{ |context, module_info, eol, user_data|
              if eol != 1
                @list << Module.new(@operation, module_info)
              else
                callback.call @operation, @list.detect{|mod| mod.name == @name_seek }, @operation.user_data if callback
              end
            }
          end
        end                 
    end    
  end
end
