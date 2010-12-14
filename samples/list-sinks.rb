#!/usr/bin/ruby
require 'glib2'
require '../lib/pulseaudio'

pa = PulseAudio::Asynchronous::Context.new 
pa.state_callback_proc = Proc.new{ |context, user_data|
   puts "Connection state has changed to #{context.state}"
    
   if context.state == :ready
     puts "I am connected, my index is #{context.index}"
     
     context.operation.sinks.all do |operation, list, user_data|
       puts "List of all sinks:"
       
       puts list.inspect
     end
   end
}
                             
pa.connect

mainloop = GLib::MainLoop.new
mainloop.run
