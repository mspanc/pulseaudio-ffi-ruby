#!/usr/bin/ruby
require 'glib2'
require '../lib/pulseaudio'

pa = PulseAudio::Asynchronous::Context.new :properties => { "media.role" => "production" } 
pa.state_callback_proc = Proc.new{ |context, user_data|
   puts "Connection state has changed to #{context.state}"
    
   if context.state == :ready
     puts "I am connected, my index is #{context.index}"
     
     context.operation.clients.all do |operation, list, user_data|
       puts "List of all clients connected to this PulseAudio server:"
       
       puts list.inspect
     end
   end
}
                             
pa.connect

mainloop = GLib::MainLoop.new
mainloop.run
