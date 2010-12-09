require 'ffi'

module PulseAudio
  LIB_PA = [ "libpulse.so.0", "libpulse.so", "libpulse" ]
  LIB_PA_GLIB_MAINLOOP = [ "libpulse-mainloop-glib.so.0", "libpulse-mainloop-glib.so", "libpulse-mainloop-glib" ]
  LIB_GLIB = [ "libglib-2.0.so.0", "libglib-2.0.so", "libglib-2.0" ]
  VERSION = "0.0.1"
  
  CHANNELS_MAX = 32 # taken from sample.h, has to be 32-bit unsigned integer
end

require 'lib/asynchronous/errors'
require 'lib/asynchronous/types/structures'
require 'lib/asynchronous/mainloop/glib'
require 'lib/asynchronous/context'
require 'lib/asynchronous/operation'
require 'lib/asynchronous/client'

