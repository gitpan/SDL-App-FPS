#!/usr/bin/perl -w

# a simple game, press 'f' to toggle fullscreen, space to pause it, and
# q for quit.

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use SDL::App::FPS::MyMandel;

my $options = { width => 640, height => 480, max_fps => 20 };

print "SDL Mandelbrot (C) v0.02 2002,2003 by Tels <http://Bloodgate.com/>\n\n";

my $app = SDL::App::FPS::MyMandel->new( $options );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
