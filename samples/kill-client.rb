#!/usr/bin/ruby

# Run connect.rb first

require 'glib2'
require '../lib/pulseaudio'

pa = PulseAudio::Asynchronous::Context.new 
pa.state_callback_proc = Proc.new{ |context, user_data|
   puts "Connection state has changed to #{context.state}"
    
   if context.state == :ready
     puts "I am connected, my index is #{context.index}"
     
     context.operation.clients.find("connect.rb") do |operation, client, user_data|
       puts "Following client is instance of connect.rb:"
       
       puts client.inspect
       
       client.operation.kill! do |operation, success, user_data|
         puts "Killed"
       end
     end
   end
}
                             
pa.connect

mainloop = GLib::MainLoop.new
mainloop.run
