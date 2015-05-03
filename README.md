# lsbtool

 LSBTool 
 Version:    1.0.6
 Date:       2015.05.03
 Author:    patrick

# Description

 LSBTool is tool to solve one of stegano problems which provides 2 methods to work with image.

 1. Inject image in any of (1..8) bits and any of (red, green, blue) channel and index is set of channel(rgb) per pixel.
 2. Look for some injection in image.

# Options

 1. `-i  pic` : Inject picture
 2. `-l  pic` : Look for lsb injection
 3. `-b  bit` : (Inject | Look for) bit [8..1]
 4. `-ch chl` : (Inject | Look for) channel (red|green|blue) and alpha only for search
 5. `-c  ctn` : Injection's content
 6. `-o  pic` : Output picture name

# Usage

 ```bash
    perl lsbtool.pl -i file.png -b 1 -ch red -c InjectedText
 ```

 ```bash
    perl lsbtool.pl -l file.png -b 1 -ch red
 ```

#Support

 Tool can find lsb injection in follow image formats:

1. PNG
2. JPG
3. GIF

# Dependencies

 GD.pm - perl module.
 https://github.com/lstein/Perl-GD

# TODO

1. Refactoring
2. Add comments
3. Implement alpha channel injection
