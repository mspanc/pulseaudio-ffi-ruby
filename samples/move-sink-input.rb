#!/usr/bin/ruby
require 'glib2'
require '../lib/pulseaudio'

def not_enough_objects
   $stderr.puts "This sample script requires at least one active sink input and at least two active sinks."
   $stderr.puts "Please start any audio playback (to provide sink input) and connect two soundcards (to provide two sinks)."
   exit 1
end

selected_sink_input = nil
selected_sinks = []
currently_selected_sink = 0

pa = PulseAudio::Asynchronous::Context.new 
pa.state_callback_proc = Proc.new{ |context, user_data|
   if context.state == :ready
     puts "Connected"
     
     context.operation.sink_inputs.all do |operation, list, user_data|
       not_enough_objects if list.size == 0
       
       selected_sink_input = list.first


       context.operation.sinks.all do |operation, list, user_data|
         not_enough_objects if list.size < 2

         selected_sinks[0] = list[0]
         selected_sinks[1] = list[1]

         puts "Sink input #{selected_sink_input.inspect} will switch it's output between sinks #{selected_sinks[0].inspect} and #{selected_sinks[1].inspect} every two seconds."
         
         GLib::Timeout.add_seconds 2 do
           if currently_selected_sink == 0
             currently_selected_sink = 1
           else
             currently_selected_sink = 0
           end           
           
           puts "Switch to #{selected_sinks[currently_selected_sink].inspect}"
           
           selected_sink_input.operation.move_to_sink! selected_sinks[currently_selected_sink] 
           
           
           true
         end
       end
     end
   end
}
                             
pa.connect

mainloop = GLib::MainLoop.new
mainloop.run
