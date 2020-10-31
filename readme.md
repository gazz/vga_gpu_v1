# sprite based VGA graphics card

- takes some inspiration from NES & other 80s computers
- will only support sprite based output

## Main components

- instruction buffer (reads in multiple 8bit instructions and concatenates as one)
- instruction decoder figures out what to do
- signal generator does vga compatible 640x480@60Hz signal output with VSync & HSync
- pixel generator feeds color information to signal generator based on current scanline/horizontal pixel
