#!/usr/bin/ruby
require 'glib2'
require '../lib/pulseaudio'


pa = PulseAudio::Asynchronous::Context.new 
pa.state_callback_proc = Proc.new{ |context, user_data|
   if context.state == :ready
     puts "Connected"
     
     context.operation.modules.all do |operation, list, user_data|
       puts "Loaded modules are #{list.inspect}"
       puts 
       
       context.operation.modules.load "module-null-sink" do |operation, mod, user_data|
         puts "Loaded module #{mod.inspect}"

         mod.operation.unload! do |operation, success, user_data|
           puts "Unloaded module."
           
           # TODO change that for associated sink seeking
         end
       end
     end
   end
}
                             
pa.connect

mainloop = GLib::MainLoop.new
mainloop.run
