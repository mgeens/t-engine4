T-Engine is distributed with the following software implementation of OpenAL:
OpenAL Soft: http://kcat.strangesoft.net/openal.html

  If you would like to use your system's OpenAL implementation instead, simply
delete or rename the OpenAL32.dll file in your T-Engine directory.  If T-Engine
refuses to run after renaming or deleting this file, your system does not
provide an OpenAL implementation and you must use the OpenAL32.dll provided
in the T-Engine distribution.

Build info:
--------------------------
Cross-built using gcc version 7.3-posix 20180318 (GCC)
library       rev       linking
SDL2          hg-8038   S
SDL2_image    hg-435    S
SDL2_ttf      hg-260    S
zlib          1.2.11    S
libpng        1.6.34    S
freetype      2.8.1     S
libogg        1.3.3     S
libvorbis     1.3.6     S
OpenAL Soft   1.18.2    D
