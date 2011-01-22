#!/usr/bin/ruby
require 'glib2'
require '../lib/pulseaudio'

pa = PulseAudio::Asynchronous::Context.new 
pa.state_callback_proc = Proc.new{ |context, user_data|
    
   if context.state == :ready
     puts "I am connected, my index is #{context.index}"
     
     context.sinks.all do |operation, list, user_data|
       puts "List of all sinks:"
       puts list.inspect
     end

     context.sink_inputs.all do |operation, list, user_data|
       puts "List of all sink inputs:"
       puts list.inspect
     end

     context.sources.all do |operation, list, user_data|
       puts "List of all sources:"
       puts list.inspect
     end

     context.source_outputs.all do |operation, list, user_data|
       puts "List of all source outputs:"
       puts list.inspect
     end
   end
}
                             
pa.connect

mainloop = GLib::MainLoop.new
mainloop.run
