#!/usr/bin/ruby
require 'glib2'
require '../lib/pulseaudio'

mainloop = GLib::MainLoop.new

pa = PulseAudio::Asynchronous::Context.new 
pa.state_callback_proc = Proc.new{ |context, user_data|
   if context.state == :ready
     context.sink_inputs.all do |operation, list, user_data|
       puts "#{list.size} sink input(s) available."
       
       list.each do |si|
         puts <<-END
    index: #{si.index}
        driver: <#{si.driver}>
        flags: TODO
        state: TODO
        sink: #{si.sink_index}
        volume: TODO
        muted: #{si.muted? ? "yes" : "no"}
        current latency: #{sprintf("%.2f", si.buffer_usec / 1000.0)} ms
        requested latency: TODO - look to the pacmd sources
        sample spec: #{si.sample_spec[:format]} #{si.sample_spec[:channels]}ch #{si.sample_spec[:rate]}Hz
        channel map: TODO
        resample method: #{si.resample_method}
        module: #{si.owner_module_index}
        client: #{si.client_index}
        properties:
         END
         
         si.proplist.each do |k,v|
           puts "                #{k} = \"#{v}\""
         end
          
       end
       
       mainloop.quit
     end

   elsif context.state == :failed or context.state == :terminated
     "Cannot connect to PA daemon"
     mainloop.quit
     exit 1
   end
}
                             
pa.connect

mainloop.run
