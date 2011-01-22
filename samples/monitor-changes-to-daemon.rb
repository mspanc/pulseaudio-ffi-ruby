#!/usr/bin/ruby
require 'glib2'
require '../lib/pulseaudio'

pa = PulseAudio::Asynchronous::Context.new 
pa.state_callback_proc = Proc.new{ |context, user_data|
  if context.state == :ready
    puts "I am connected, my index is #{context.index}"
    pa.subscribe! :all do |context, success, user_data|
      puts "Subscribed"
    end
  end
}
                  
pa.subscribe_callback_proc = Proc.new{ |context, facility, event_type, index, user_data| 
  puts "#{facility} #{event_type} #{index}"
}
           
pa.connect

mainloop = GLib::MainLoop.new
mainloop.run
