require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "pulseaudio-ffi"
    gemspec.summary = "PulseAudio bindings via FFI"
    gemspec.description = "PulseAudio sound server bindings via FFI interface"
    gemspec.email = "marcin@saepia.net"
    gemspec.homepage = "https://github.com/saepia/pulseaudio-ffi-ruby/"
    gemspec.authors = ["Marcin Lewandowski"]
    
    gemspec.files = FileList['doc/**/*.html', 'samples/**/*.rb', 'lib/**/*.rb', 'GPL3-LICENSE', 'Rakefile', 'VERSION']
    gemspec.add_dependency "ffi"    

    Jeweler::GemcutterTasks.new
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end


