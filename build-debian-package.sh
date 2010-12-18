#!/bin/bash
source /etc/lsb-release


rm -rf pulseaudio-ffi-ruby1.8/

mkdir pulseaudio-ffi-ruby1.8/
mkdir pulseaudio-ffi-ruby1.8/DEBIAN
echo "Package: pulseaudio-ffi-ruby1.8
Version: `cat VERSION`
Section: base
Priority: optional
Architecture: all
Depends: ruby, libffi-ruby, pulseaudio
Maintainer: marcin@saepia.net
Description: PulseAudio bindings for ruby via FFI interface" >> pulseaudio-ffi-ruby1.8/DEBIAN/control

mkdir -p pulseaudio-ffi-ruby1.8/usr/lib/ruby/1.8/
cp -r lib/* pulseaudio-ffi-ruby1.8/usr/lib/ruby/1.8/
find pulseaudio-ffi-ruby1.8/ | grep '/\.' | xargs rm -rf

dpkg --build pulseaudio-ffi-ruby1.8 ./
rm -rf pulseaudio-ffi-ruby1.8/

rm -rf pulseaudio-ffi-ruby/

mkdir pulseaudio-ffi-ruby/
mkdir pulseaudio-ffi-ruby/DEBIAN
echo "Package: pulseaudio-ffi-ruby
Version: `cat VERSION`
Section: base
Priority: optional
Architecture: all
Depends: pulseaudio-ffi-ruby1.8
Maintainer: marcin@saepia.net
Description: PulseAudio bindings for ruby via FFI interface" > pulseaudio-ffi-ruby/DEBIAN/control

find pulseaudio-ffi-ruby/ | grep '/\.' | xargs rm -rf

dpkg --build pulseaudio-ffi-ruby ./
rm -rf pulseaudio-ffi-ruby/

