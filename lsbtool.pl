#!/usr/bin/perl
#author patrick
#stegano lsbtool
#version 1.0.6
#date 2015.05.03

use GD; # https://github.com/lstein/Perl-GD

$\=$/;

$injectLSB = 1;
$lookLSB = 2;

$picFormat;
$pic;
$out = "corrupted.png";

$PNG = "png";
$GIF = "gif";
$JPG = "jpg";

$RED = "red";
$GREEN = "green";
$BLUE = "blue";
$ALPHA = "alpha";
$RGB = "rgb";

$content = "";

&parse;
&initBinaryMess;
&lsb($lsbMethod);


sub parse {
    $argv = join(' ', @ARGV);

    if ($argv =~ /-l/) {
        $lsbMethod = $lookLSB;
    } elsif ($argv =~ /-i/) {
        $lsbMethod = $injectLSB;
    } else {
        &goout;
    }

        if ($argv =~ /-c\s(\S+)/) {
            $content = $1;
        }

        if ($argv =~ /\s-b\s([1-8])\s*/) {
            $cbit = $1;
        } else {
            &goout;
        }

        if ($argv =~ /\s-ch\s(red|green|blue|alpha)/) {
            $channel = $1;
        } else {
            $channel = $RGB;
        }

    if ($argv =~ /\s(\S*\.(png|jpg|gif))/) {
        $pic = $1;
        $picFormat = $2;
    } else {
#       &goout;
    }

    if ($argv =~ /-o\s(\S*)\s/) {
        $out = $1;
    }

    if ($argv =~ /-v/) {
        &info;
    }
}

sub info {
    print "perl lsbtool.pl:";
    print "\tfile: " . $pic;
    print "\tfile format: " . $picFormat;
    print "\tLSBMethod: " . (($lsbMethod == 1) ? "injection" : "search");
    print "\tBit: " . $cbit;
    print "\tChannel: " . $channel;
    print "\tContent: " . $content;
    print "\toutput file: " . $out;
}

sub goout {
    print "Usage: lsbtool.pl [args] picture.(png|jpg|gif)";
    print "\t-i  pic : Inject picture";
    print "\t-b  bit : Inject bit [8..1]";
    print "\t-ch chl : Inject channel (red|green|blue)  and alpha only for search";
    print "\t-c  ctn : Inject content";
    print "\t-o  pic : Output picture name";
    print "\t-l  pic : Look for lsb"; 
    print "E.q. perl lsbtool.pl -i picture.png -o output.png -b 1 -ch red -c sometext"; 
    print "E.q. perl lsbtool.pl -l picture.png -b 1 -ch red"; 
    exit;
}

sub lsb {
    
    $lsbMethod = shift;
    $sourceImg = 1;

    if ($picFormat =~ /png/) {
        $x = newFromPng GD::Image($pic, $sourceImg) || die;
    } elsif ($picFormat =~ /jpg/) {
        $x = newFromJpeg GD::Image($pic, $sourceImg) or die;
    } else {
        $x = newFromGif GD::Image($pic, $sourceImg) or die;
    }
        

    ($w,$h) = $x->getBounds();

    for ($i = 0; $i < $h; $i++) { # $i < $h
        for ($j = 0; $j < $w; $j++) {
            $index = $x->getPixel($j, $i);
            ($r, $g, $b) = $x->rgb($index);
            $t = $x->transparent($index);
           
            $count = $i*$w + $j;

            if ($lsbMethod == $injectLSB) {
                &inject;
            }

            if ($lsbMethod == $lookLSB) {
                push @r1, $r;
                push @g1, $g;
                push @b1, $b;
                push @t1, $t;
                push @index, $index;
            }

        }
    }
    
    if ($lsbMethod == $lookLSB) {
        &look;
    }
}

sub inject {
    
    $lsb = $cbit;
                
    if ($count <= $binaryMessageSize) { 
        if ($channel == $RED) {
            $r = injectChannel($count, $r, $lsb);
            $index=$x->colorAllocate($r, $g, $b);
        } elsif ($channel == $GREEN) {
            $g = injectChannel($count, $g, $lsb);
            $index=$x->colorAllocate($r, $g, $b);
        } elsif ($channel == $BLUE){
            $b = injectChannel($count, $b, $lsb);
            $index=$x->colorAllocate($r, $g, $b);
        } else {
            $index = injectChannel($count, $index, $lsb);
        }
        # TODO inject alpha

    }

    $x->setPixel($j, $i, $index);


    if ($count > $binaryMessageSize) {
        $png_data = $x->png;
        open (OUT, ">" ,$out) || die;
        binmode OUT;
        print OUT $png_data;
        close OUT;
        exit;
    }
}

sub look {

    $lsb = $cbit;
    if ($channel == $RED) {
        &searchlsb($lsb, \@r1);
    } elsif ($channel == $GREEN) {
        &searchlsb($lsb, \@g1);
    } elsif ($channel == $BLUE) {
        &searchlsb($lsb, \@b1);
    } elsif ($channel == $ALPHA) {
        &searchlsb($lsb, \@t1);
    } else {
        &searchlsb($lsb, \@index);
    }
}

sub searchlsb {
  
    $lsb = shift;
    $colorList = shift;
    @lsbbits = map {substr(unpack("B*", pack("N", $_)),-$lsb, $lsb)} @$colorList;
    $bits = join('', @lsbbits);
    @mess = map {chr(unpack("N", pack("B32", substr("0" x 32 . $_, -32))))} $bits =~ m/\d{8}/g;
    $res = join('', @mess);

#    &info;

    print "-" x 30 . "LSB Analys" . "-" x 30;
    print $res;
    print "-" x 70;
}

sub injectChannel {

    $count = shift;
    $color = shift;
    $corruptedBit = shift;
    $ind = $count % $lens{1};

    $bit = @binaryMessage[$ind];
    
    $bits = substr((unpack "B*",  pack('N', $color)), -8);
    $colorBits = substr($bits, 0, 8-$corruptedBit) . $bit . substr($bits, 9-$corruptedBit);
    $cBits = unpack("N", pack("B32", substr("0" x 32 . $colorBits, -32)));
    return $cBits;
}

sub initBinaryMess {

    @binaryMessage = map {$_} (unpack "B*", $content) =~ m/\d/g;
    $binaryMessageSize = $#binaryMessage+1; 
    %lens = (1 , $binaryMessageSize);
}
